shopt -s inherit_errexit

directory="${UNIFY_DIRECTORY:-/etc/nixos}"

hue "$directory"
cd "$directory"

full_contents=$(cat flake.lock)

check_input()
{
  input=$1
  data=$(echo "$full_contents" | jq -r --arg input "$input" '.nodes.[$input]')

  # The input will never update if it points to a specific commit hash
  evergreen=$(echo "$data" | jq -r "if .original.rev then 0 else 1 end")

  if [ "$evergreen" == 0 ]; then
    exit 0 # equivalent of `continue` within a subshell, move onto next input
  fi


  url=$(echo "$data" | jq -r '"https://" + .original.type + ".com/" + .locked.owner + "/" + .original.repo + ".git"')
  branch=$(echo "$data" | jq -r 'if .original.ref then .original.ref else "HEAD" end')

  oldHash=$(echo "$data" | jq -r ".locked.rev")

  if [ "$branch" == "HEAD" ]; then # It doesn't fetch properly with --branches when fetching HEAD
    newHash=$(git ls-remote "$url" "$branch" | cut -f1)
  else
    newHash=$(git ls-remote --branches "$url" "$branch" | cut -f1)
  fi

  if [ "$newHash" == "" ]; then
    echo "BAD, $input FAILED TO FETCH"
    exit 1
  fi

  # If input has been updated
  if [ "$oldHash" != "$newHash" ]; then
    echo "$input"
  fi
}

inputs=$(echo "$full_contents" | jq -r ".nodes.root.inputs | keys[]")

echo "Inputs that need updating:"

# Parallelize checks for each input
for i in $inputs; do
  check_input "$i" &
done

wait # Don't exit script till all parallel checks are done
