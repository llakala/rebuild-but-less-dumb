{ pkgs, ... }:
pkgs.writeShellApplication
{
  name = "rbld";
  runtimeInputs = with pkgs;
  [
    nix-output-monitor # aka nom
    nixos-rebuild
    git
  ];

  text =
  ''
    set -e

    directory="/etc/nixos" # Default path unless -d is passed
        
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

    git add -AN # Adds the existence of any new files, but not their contents
    nixos-rebuild switch \
      --use-remote-sudo --fast \
      --log-format internal-json \
      |& nom --json || exit 1

    '';
}
