#! /usr/bin/env fish

function default
    for val in $argv
        if [ -n "$val" ]
            echo $val
            break
        end
    end
end

# Equivalent of "${UNIFY_DIRECTORY:/etc/nixos}" in bash
set directory (default $UNIFY_DIRECTORY "/etc/nixos")

set -l option1 (fish_opt --required --short d --long directory)
set options $option1
argparse $options -- $argv

# Override value with `-d` / `--directory`
if set -q _flag_directory
    set directory $_flag_directory
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
    fight $input $full_contents &
end

wait
