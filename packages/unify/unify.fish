#!/usr/bin/env fish

# Use environment variables if they're overriding the default values
# Directory that your NixOS config is located in
set DIRECTORY (revive $UNIFY_DIRECTORY "/etc/nixos")

# Trigger `nix flake update` if one of these inputs is updated
# We don't split this yet for easier sending to `balc`
set INPUTS (revive $UNIFY_TRACKED_INPUTS "nixpkgs menu")

# The commit message to use for flake.lock updates
set COMMIT_MESSAGE (revive $UNIFY_COMMIT_MESSAGE "flake: update flake.lock")

# branches that are allowed to have flake.lock changes commited to
set PRIMARY_BRANCHES (revive $UNIFY_PRIMARY_BRANCHES "main master" | string split -n " ")

set -l option1 (fish_opt --required --short d --long directory)
set -l option2 (fish_opt --required --short i --long inputs)
set -l option3 (fish_opt --required --short c --long commit_message)
set -l option4 (fish_opt --required --short p --long primary_branches)

set options $option1 $option2 $option3 $option4
argparse $options -- $argv

if set -q _flag_directory
    set DIRECTORY $_flag_directory
end

if set -q _flag_inputs
    set INPUTS $_flag_inputs
end

if set -q _flag_commit_message
    set COMMIT_MESSAGE $_flag_commit_message
end

if set -q _flag_primary_branches
    set PRIMARY_BRANCHES $_flag_primary_branches
end

# Called as a trap so we cleanup all state after running or when interrupted
# State currently means flake.lock changes or branch being swapped
function cleanup_state
    set current_branch (git branch --show-current)

    if [ $current_branch != $previous_branch ]
        echo "Returning back to branch $previous_branch"
        git switch --quiet $previous_branch
    end

    # If flake.lock has been modified
    if ! git diff --exit-code --quiet flake.lock
        echo "Undoing flake.lock changes."
        git restore flake.lock
    end
end

# Return whether we're on one of the branches stored in PRIMARY_BRANCHES
function on_primary_branch
    set -l current_branch $argv[1]

    for primary_branch in $PRIMARY_BRANCHES
        if [ $current_branch = $primary_branch ]
            return 0
        end
    end

    return 1
end

# Return 1 if we couldn't find a primary branch to switch into
function switch_to_primary
    for branch in $PRIMARY_BRANCHES
        if git rev-parse --verify $branch >/dev/null 2>&1
            echo "Switching to primary branch $branch"
            git switch --quiet $branch
            return 0
        end
    end
    return 1
end

# Check that the passed directory was valid
hue $DIRECTORY || exit 1
cd $DIRECTORY

# Only set this *after* entering $DIRECTORY
set previous_branch (git branch --show-current)

# Check if we need to swap to a primary branch
if not on_primary_branch $previous_branch

    # Exit early if we have uncommmitted changes in non-primary branch
    if test -n "$(git status --porcelain)"
        echo "You have uncommitted changes in your current branch `$previous_branch`."
        echo "Unify only updates flake inputs on the primary branch, as it's likely what you meant to do."
        echo "You can specify the primary branch/branches to be swapped to like this:"
        echo '`unify -p "main master"`'
        echo "If your working tree is clean, Unify will then switch to a primary branch automatically."
        exit 1
    end

    # Attempt to switch to primary branch, and exit if we fail to
    if not switch_to_primary
        echo "You provided the primary branches `$PRIMARY_BRANCHES` to be switched to automatically."
        echo "However, none of these branches were found in directory `$DIRECTORY`."
        exit 1
    end
end

# From here on, we may have state that needs cleaning up on script exiting
# No matter how we exit, cleanup any state that exists
# We also catch SIGINT to ensure Ctrl+C is caught
trap cleanup_state EXIT SIGINT

# Custom command that checks whether we care about updated inputs.
# Alternative implementations coming!
balc $INPUTS || exit

rbld -d $DIRECTORY || exit

git commit --quiet --message $COMMIT_MESSAGE flake.lock

if ! git ls-remote origin --quiet
    # For when internet is spotty
    echo "Can't reach the remote repo to push. Try pushing again later."
    exit 1
end

echo "Connection found, pushing."
git push --quiet
