shopt -s inherit_errexit

directory="${RBLD_DIRECTORY:-/etc/nixos}"

hue "$directory"
cd "$directory"

contents=$(cat flake.lock)
inputs=$(echo "$contents" | jq -r ".nodes.root.inputs | keys[]")

for input in $inputs; do
  data=$(echo "$contents" | jq -r --arg input "$input" '.nodes.[$input]')


  # The input will never update if it points to a specific commit hash
  evergreen=$(echo "$data" | jq -r "if .original.rev then 0 else 1 end")

  if [ "$evergreen" == 0 ]; then
    continue
  fi


  url=$(echo "$data" | jq -r '"https://" + .original.type + ".com/" + .locked.owner + "/" + .original.repo + ".git"')
  branch=$(echo "$data" | jq -r 'if .original.ref then .original.ref else "HEAD" end')
  oldHash=$(echo "$data" | jq -r ".locked.rev")

  newHash=$(git ls-remote "$url" "$branch" | cut -f1)

  if [ "$oldHash" != "$newHash" ]; then
    output+=$input
  fi

done

echo "$output"
