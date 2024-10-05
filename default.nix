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
    set -e # Exit early if any commands fail
    CONFIG_DIRECTORY=/etc/nixos
    cd $CONFIG_DIRECTORY

    get_time() # Get flake.lock revisions times for the inputs we care about
    {
      jq -r '([.nodes["home-manager", "nixpkgs", "nixpkgs-unstable"].locked.lastModified] | add)' flake.lock
    }

    case "$1" in
      -n)
        git add -AN
        nixos-rebuild switch \
          --use-remote-sudo --fast \
          --log-format internal-json \
          |& nom --json || return
        ;;

      -f)
        OLD_TIME=$(get_time)
        nix flake update
        NEW_TIME=$(get_time)

        echo "Old time: $OLD_TIME" # Logs for debugging
        echo "New time: $NEW_TIME"

        if [[ $NEW_TIME == "$OLD_TIME" ]]; then
          echo "No important updates to flake.lock, so skipping rebuild"
          exit 0
        fi

        rbld -n # If we fail here, we exit early and don't commit something broken
        git commit -q -m "flake: update flake.lock" flake.lock
        git push
        ;;

      *)
        cat <<EOF
        ${"\n" + ''
        Usage: rbld (-n|-f|)
        Options:
        -n          Rebuild the system configuration
        -f          Update the flake.lock and rebuild if necessary
      ''}EOF
        ;;

    esac
  '';
}
