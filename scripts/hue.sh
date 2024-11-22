shopt -s inherit_errexit

# Hue-specific errors for ensuring we got a directory
if [ "$#" = 0 ]; then
  echo "Hue wasn't provided a directory as a positional parameter."
  exit 1
elif [ "$#" -gt 1 ]; then
  echo "Too many positional parameters were provided to Hue. Only one was expected."
  exit 1
fi

DIRECTORY=$1

if [ ! -d "$DIRECTORY" ]; then
  echo "Directory \`$DIRECTORY\` does not exist, and can't be used for rebuilding."
  exit 1
fi

cd "$DIRECTORY" # So we can test on the current directory

if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
  echo "Directory \`$DIRECTORY\` isn't a git repo, and was expected to be one."
  exit 1
fi

if [[ ! -f flake.nix ]]; then
  echo "Directory \`$DIRECTORY\` doesn't contain a \`flake.nix\` file."
  exit 1
fi

exit 0
