{ pkgs, ... }:
pkgs.writeShellApplication
{
  name = "rbld";
  runtimeInputs = with pkgs;
  [
    jq
    nix-output-monitor # aka nom
    nixos-rebuild
    home-manager
    git
  ];

  text =
  ''
    set -e
    set +u # NOUNSET RUINS MY DAY, we need to unset it to check whether $1 was passed

    directory="/etc/nixos" # Default path unless -d is passed
    PRIMARY_BRANCHES=("main" "master")

    usage()
    {
      echo "Usage: rbld [type] [options]"
      echo "Types:"
      echo "    nixos        Rebuild the system configuration (defaults to this if no type is passed)"
      echo "    flake        Update the flake.lock and rebuild if necesssary"
      echo "Options:"
      echo "    -d DIR       Specify the NixOS config directory location (default: /etc/nixos)"
      exit 0
    }

    get_time() # Get flake.lock revisions times for the inputs we care about
    {
      jq -r '([.nodes["home-manager", "nixpkgs", "nixpkgs-unstable", "rbld"].locked.lastModified] | add)' flake.lock
    }

    switch_back() # Called as a trap so we return from main/master to whatever branch the user was on
    {
      CURRENT_BRANCH=$(git branch --show-current)
      if [[ $CURRENT_BRANCH != "$PREVIOUS_BRANCH" ]]; then
        git switch --quiet "$PREVIOUS_BRANCH"
      fi
    }

    in_primary_branch() # Check if we're currently on the primary branch
    {
      current_branch=$1

      for primary_branch in "''${PRIMARY_BRANCHES[@]}"; do

        if [[ $current_branch == "$primary_branch" ]]; then
          return 0
        fi

      done
      return 1
    }

    switch_to_primary_branch() # Return 1 if we couldn't find a primary branch to switch into
    {
      for branch in "''${PRIMARY_BRANCHES[@]}"; do
        if git rev-parse --verify "$branch" > /dev/null 2>&1; then
          git switch --quiet "$branch"
          return 0
        fi
      done

      return 1
    }

    if [[ -z "$1"  ]]; then # Easy solution since we couldn't get ''${1:-nixos} syntax working
      ACTION="nixos"
    else
      ACTION="$1"
      shift
    fi

    while getopts ":d:" opt; do
      case $opt in
        d)
          directory=$OPTARG
          ;;
        \?) # Undefined option like -q
          echo "Invalid option: -$OPTARG" >&2
          exit 1
          ;;
        :) # Setting -d without an argument
          echo "Option -$OPTARG requires an argument." >&2
          exit 1
          ;;
      esac
    done

    cd "$directory"

    if [[ $ACTION == "nixos" ]]; then
      git add -AN # Adds the existence of any new files, but not their contents
      nixos-rebuild switch \
        --use-remote-sudo --fast \
        --log-format internal-json \
        |& nom --json || exit 1


    elif [[ $ACTION == "flake" ]]; then
      PREVIOUS_BRANCH=$(git branch --show-current)

      if [[ -n $(git status --porcelain) ]] && ! in_primary_branch "$PREVIOUS_BRANCH"; then # Exit early if we're not in primary branch and have uncommited changes
        echo "You have uncommited changes in your current branch $PREVIOUS_BRANCH."
        echo "Please stash your changes and try again."
        exit 1
      fi


      if ! switch_to_primary_branch; then
        echo "Your primary branch can't be found to be swapped to."
        echo "Complain on Github Issues and I'll add a parameter to choose the primary branch."
        exit 1
      fi


      trap switch_back EXIT err # When script ends, swap back to the branch the user was on before

      OLD_TIME=$(get_time)
      nix flake update
      NEW_TIME=$(get_time)

      echo "Old time: $OLD_TIME" # Logs for debugging
      echo "New time: $NEW_TIME"

      if [[ $NEW_TIME == "$OLD_TIME" ]]; then
        echo "No important updates to flake.lock, so skipping rebuild"
        git restore flake.lock # Not ideal since we'll be redoing changes every time, but needed to return to a previous branch
        exit 0
      fi

      rbld nixos -d "$directory" # If we fail here, we exit early and don't commit something broken
      git commit -q -m "flake: update flake.lock" flake.lock
      
      if ! git ls-remote origin; then # For when internet is spotty
        echo "Can't reach the remote repo to push. Try pushing again later."
        exit 1
      fi

      echo "Connection found, pushing."
      git push


    else # When something like `rbld fjdsfh` is passed
      echo "Invalid argument passed: $ACTION" >&2
      exit 1

    fi
    '';
}
