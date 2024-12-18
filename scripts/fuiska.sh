shopt -s inherit_errexit

directory="${RBLD_DIRECTORY:-/etc/nixos}"

hue "$directory"
cd "$directory"
ls
