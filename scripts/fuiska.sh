shopt -s inherit_errexit

directory="${RBLD_DIRECTORY:-/etc/nixos}"

hue "$directory"
cd "$directory"

contents=$(cat flake.lock)
inputs=$(echo "$contents" | jq -r ".nodes.root.inputs | keys[]")

for input in $inputs; do

  data=$(echo "$contents" | jq -r --arg input "$input" '.nodes.[$input]')

  type=$(echo "$data" | jq -r ".original.type")
  owner=$(echo "$data" | jq -r ".original.owner")
  repo=$(echo "$data" | jq -r ".original.repo")
  ref=$(echo "$data" | jq -r ".original.ref") # TODO: HANDLE NULL
  hash=$(echo "$data" | jq -r ".locked.rev")

  echo "$type"
  echo "$owner"
  echo "$repo"
  echo "$ref"
  echo "$hash"
  echo ""

done
