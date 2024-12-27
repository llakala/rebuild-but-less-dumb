shopt -s inherit_errexit

# Use environment variables if they're overriding the default values

DIRECTORY="${UNIFY_DIRECTORY:-/etc/nixos}"                                # Directory that your NixOS config is located in
IMPORTANT_INPUTS="${UNIFY_TRACKED_INPUTS:-nixpkgs rebuild-but-less-dumb}" # Trigger `nix flake update` if one of these inputs is updated
FLAKE_COMMIT_MESSAGE="${UNIFY_COMMIT_MESSAGE:-flake: update flake.lock}"  # The commit message to use for flake.lock updates
PRIMARY_BRANCHES="${UNIFY_PRIMARY_BRANCHES:-main master}"                 # branches that are allowed to have flake.lock changes commited to

# Override default values without setting a permanent custom default via environment vars
while getopts ":d:i:c:p:" opt; do
  case $opt in
    d)
      DIRECTORY=$OPTARG
      ;;
    i)
      IMPORTANT_INPUTS=$OPTARG
      ;;
    c)
      FLAKE_COMMIT_MESSAGE=$OPTARG
      ;;
    p)
      PRIMARY_BRANCHES=$OPTARG
      ;;
    \?) # Undefined option like -q
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
    :) # using an argument without passing something (ex: `unify -d`)
      echo "Option -$OPTARG requires an argument." >&2
      exit 1
      ;;
  esac
done

# Call get_revision_time for each input in IMPORTANT_INPUTS
sum_all_revisions()
{
  sum=0
  for input in $IMPORTANT_INPUTS; do
    time=$(
      <flake.lock jq --arg input "$input" \
        '.nodes.[$input].locked.lastModified'
    )
    if [[ $time == "null" ]]; then
      echo "Input \`$input\` wasn't found in the flake.lock. Maybe you named it something else, or made a typo?"
      return 1
    fi

    sum=$((sum + time))
  done
  echo "$sum" # Returns value of sum
}

# Called as a trap so we cleanup all state after running or when interrupted
# State currently means flake.lock changes or branch being swapped
cleanup_state()
{
  current_branch=$(git branch --show-current)
  if [[ $current_branch != "$previous_branch" ]]; then
    echo "Returning back to branch $previous_branch"
    git switch --quiet "$previous_branch"
  fi

  # If flake.lock has been modified
  if ! git diff --exit-code --quiet flake.lock; then
    echo "Undoing flake.lock changes."
    git restore flake.lock
  fi
}

# Return whether we're on one of the branches stored in PRIMARY_BRANCHES
on_primary_branch()
{
  local current_branch=$1

  for primary_branch in $PRIMARY_BRANCHES; do

    if [[ $current_branch == "$primary_branch" ]]; then
      return 0
    fi

  done
  return 1
}

# Return 1 if we couldn't find a primary branch to switch into
switch_to_primary()
{
  for branch in $PRIMARY_BRANCHES; do
    if git rev-parse --verify "$branch" >/dev/null 2>&1; then
      echo "Switching to primary branch $branch"
      git switch --quiet "$branch"
      return 0
    fi
  done

  return 1
}

hue "$DIRECTORY" # Check that the passed directory was valid
cd "$DIRECTORY"

previous_branch=$(git branch --show-current) # Only set this *after* entering $DIRECTORY

# Check if we need to swap to a primary branch
if ! on_primary_branch "$previous_branch"; then

  # Exit early if we have uncommmitted changes in non-primary branch
  if [[ -n $(git status --porcelain) ]]; then
    echo "You have uncommitted changes in your current branch \`$previous_branch\`."
    echo "Unify only updates flake inputs on the primary branch, as it's likely what you meant to do."
    echo "You can specify the primary branch/branches to be swapped to like this:"
    echo "\`unify -p \"main master\"\`"
    echo "If your working tree is clean, Unify will then switch to a primary branch automatically."
    exit 1
  fi

  # Attempt to switch to primary branch, and exit if we fail to
  if ! switch_to_primary; then
    echo "You provided the primary branches \`$PRIMARY_BRANCHES\` to be switched to automatically."
    echo "However, none of these branches were found in directory \`$DIRECTORY\`."
    exit 1
  fi

fi

# From here on, we may have state that needs cleaning up on script exiting / Ctrl+C
# No matter how we exit, cleanup any state that exists
trap cleanup_state EXIT

if ! old_time=$(sum_all_revisions); then
  echo "$old_time" # We return the error message from the function directly
  exit 1
fi
nix flake update
new_time=$(sum_all_revisions) # We only check for errors once, and don't check again here. Should be fine (hopefully).

echo "Old time: $old_time" # Logs for debugging
echo "New time: $new_time"

if [[ $old_time == "$new_time" ]]; then
  echo "No important updates to flake.lock, so skipping rebuild"
  exit 0 # We revert flake.lock in the trap, so no need to do it here
fi

rbld -d "$DIRECTORY"
git commit --quiet --message "$FLAKE_COMMIT_MESSAGE" flake.lock

if ! git ls-remote origin --quiet; then # For when internet is spotty
  echo "Can't reach the remote repo to push. Try pushing again later."
  exit 1
fi

echo "Connection found, pushing."
git push --quiet
