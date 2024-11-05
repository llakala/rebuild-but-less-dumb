{ pkgs, ... }:
pkgs.writeShellApplication
{
  name = "unify";
  runtimeInputs = with pkgs;
  [
    git
    jq
    nix
    bash
  ];
  excludeShellChecks = # Shellcheck checks to ignore. ex: "SC2016"
  [

  ];
  bashOptions =
  [
    "nounset" # -u
    "errexit" # -e
    "pipefail"
    "errtrace" # -E
  ];
  text = 
  ''
    shopt -s inherit_errexit

    PRIMARY_BRANCHES="main master"

    # Use environment variables if they're overriding the default values
    DIRECTORY="''${FLAKE:-/etc/nixos}"
    IMPORTANT_INPUTS="''${INPUTS_TRIGGERING_REBUILD:-nixpkgs rebuild-but-less-dumb}"

    while getopts ":d:i:" opt; do # Overrides environment variables values
      case $opt in
        d)
          DIRECTORY=$OPTARG
          ;;
        i)
          IMPORTANT_INPUTS=$OPTARG
          ;;
        \?) # Undefined option like -q
          echo "Invalid option: -$OPTARG" >&2
          exit 1
          ;;
        :) # doing `unify -d` or `unify -t` without passing something
          echo "Option -$OPTARG requires an argument." >&2
          exit 1
          ;;
      esac
    done

    sum_all_revisions() # Call get_revision_time for each input in IMPORTANT_INPUTS
    {
      sum=0
      for input in $IMPORTANT_INPUTS; do
        time=$(jq --arg input "$input" '.nodes[.nodes[.root].inputs[$input]].locked.lastModified' flake.lock)
        sum=$((sum + time))
      done
      echo "$sum" # Returns value of sum
    }

    return_to_secondary() # Called as a trap so we return from main/master to whatever branch the user was on
    {
      current_branch=$(git branch --show-current)
      if [[ $current_branch != "$previous_branch" ]]; then
        git switch --quiet "$previous_branch"
      fi
      git restore flake.lock
    }

    on_primary_branch() # Return whether we're on one of the branches stored in PRIMARY_BRANCHES
    {
      local current_branch=$1

      for primary_branch in $PRIMARY_BRANCHES; do

        if [[ $current_branch == "$primary_branch" ]]; then
          return 0
        fi

      done
      return 1
    }

    switch_to_primary() # Return 1 if we couldn't find a primary branch to switch into
    {
      for branch in $PRIMARY_BRANCHES; do
        if git rev-parse --verify "$branch" > /dev/null 2>&1; then
          git switch --quiet "$branch"
          return 0
        fi
      done

      return 1
    }


    cd "$DIRECTORY"
    previous_branch=$(git branch --show-current) # Only set this *after* entering $DIRECTORY

    if [[ -n $(git status --porcelain) ]] && ! on_primary_branch "$previous_branch"; then # Exit early if we're not in primary branch and have uncommited changes
      echo "You have uncommited changes in your current branch $previous_branch."
      echo "This script only updates flake inputs on the primary branch, as it's likely what you meant to do."
      echo "Please stash/commit your changes and try again."
      exit 1
    fi


    if switch_to_primary; then
      trap return_to_secondary EXIT # When script ends or is interrupted, swap back to the branch the user was on before
    else
      echo "Your primary branch can't be found to be swapped to."
      echo "Complain on Github Issues and I'll add a parameter to choose the primary branch."
      exit 1
    fi

    old_time=$(sum_all_revisions)
    nix flake update
    new_time=$(sum_all_revisions)

    echo "Old time: $old_time" # Logs for debugging
    echo "New time: $new_time"

    if [[ $old_time == "$new_time" ]]; then
      echo "No important updates to flake.lock, so skipping rebuild"

      echo "Undoing flake.lock changes."
      git restore flake.lock 

      exit 0
    fi

    rbld -d "$DIRECTORY"
    git commit --quiet -m "flake: update flake.lock" flake.lock
    
    if ! git ls-remote origin --quiet; then # For when internet is spotty
      echo "Can't reach the remote repo to push. Try pushing again later."
      exit 1
    fi

    echo "Connection found, pushing."
    git push --quiet


  '';
}
