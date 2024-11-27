shopt -s inherit_errexit

directory="${RBLD_DIRECTORY:-/etc/nixos}" # Override default config directory value with $FLAKE

# Or, if you just need to override the directory once, use `-d`
while [[ $# -gt 0 ]]; do
  opt="$1"
  shift

  case "$opt" in
    -d | --directory)
      directory="$1"
      shift
      ;;

    -*)
      echo "Invalid option \`$opt\`."
      exit 1
      ;;

    *)
      echo "Argument \`$opt\` passed without an option."
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
  --flake "$directory" |&
  nom --json || exit 1
