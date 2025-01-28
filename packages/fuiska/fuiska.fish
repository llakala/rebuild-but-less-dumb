#! /usr/bin/env fish

# Equivalent of "${UNIFY_DIRECTORY:/etc/nixos}" in bash
set directory (revive $UNIFY_DIRECTORY "/etc/nixos")

# Don't use API by default. boolean variable
set api (revive $MENU_USE_API "false")

set -l option1 (fish_opt --required --short d --long directory)

set -l flag1 a/api


set options $option1 $flag1
argparse $options -- $argv

# Override value with `-d` / `--directory`
if set -q _flag_directory
    set directory $_flag_directory
end

# Override value with `-a` / `--api`
if set -q _flag_api
    set api true
end


# Fail early here if hue says bad, since `set -e` doesn't exist
hue $directory || exit
cd $directory

# We use "$()" to save as a multiline string
set full_contents "$(cat flake.lock)"
set inputs (echo $full_contents | jq -r ".nodes.root.inputs | keys[]")

echo "Inputs that need updating:"

# We parallelize checking the input via `&`
for input in $inputs
    fight $input $full_contents $api &
end

wait
