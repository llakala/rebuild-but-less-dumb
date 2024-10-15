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

    switch_back()
    {
      CURRENT_BRANCH=$(git branch --show-current)
      if [[ $CURRENT_BRANCH != "$PREVIOUS_BRANCH" ]]; then
        git switch --quiet "$PREVIOUS_BRANCH"
      fi
    }

    if [[ -z "$1"  ]]; # Easy solution since we couldn't get ''${1:-nixos} syntax working
      then
        REBUILD_TYPE="nixos"
      else
        REBUILD_TYPE="$1"
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

    if [[ $REBUILD_TYPE == "nixos" ]]; then
      git add -AN
      nixos-rebuild switch \
        --use-remote-sudo --fast \
        --log-format internal-json \
        |& nom --json || return


    elif [[ $REBUILD_TYPE == "flake" ]]; then
      PREVIOUS_BRANCH=$(git branch --show-current)

      if [[ -n $(git status --porcelain) ]]; then
        echo "You have uncommited changes in your current branch $PREVIOUS_BRANCH."
        echo "Please stash your changes and try again."
        exit 1
      fi

      if git rev-parse --verify main > /dev/null; then
        git switch --quiet main
      elif git rev-parse --verify master > /dev/null; then
        git switch --quiet master
      else
        echo "Your primary branch isn't named master or main, so we can't switch to it for updating flake inputs."
        echo "Complain on Github Issues and I'll add a parameter to choose the primary branch."
        exit 1
      fi

      trap switch_back EXIT # When script ends, swap back to the branch the user was on before

      OLD_TIME=$(get_time)
      nix flake update
      NEW_TIME=$(get_time)

      echo "Old time: $OLD_TIME" # Logs for debugging
      echo "New time: $NEW_TIME"

      if [[ $NEW_TIME == "$OLD_TIME" ]]; then
        echo "No important updates to flake.lock, so skipping rebuild"
        exit 0
      fi

      rbld nixos -d "$directory" # If we fail here, we exit early and don't commit something broken
      git commit -q -m "flake: update flake.lock" flake.lock
      
      if ! git ls-remote origin; then
        echo "Can't reach the remote repo to push. Try pushing again later."
        exit 0
      fi

      echo "Connection found, pushing."
      git push


    else
      echo "Invalid parameter passed: $REBUILD_TYPE" >&2
      exit 1

    fi
    '';
}
