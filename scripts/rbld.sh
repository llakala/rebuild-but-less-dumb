shopt -s inherit_errexit

directory="${FLAKE:-/etc/nixos}" # Override default config directory value with $FLAKE

while getopts ":d:" opt; do # Or, if you just need to override the directory once, use `-d`
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

hue "$directory"
cd "$directory"

git add -AN # Adds the existence of any new files, but not their contents

sudo -v || exit # Rather than having to verify sudo during rebuild, we do it before. works as long as rebuild is <5 minutes
nixos-rebuild switch \
  --use-remote-sudo --fast \
  --log-format internal-json \
  --flake "$directory" \
  |& nom --json || exit 1
