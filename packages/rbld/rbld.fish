#! /usr/bin/env fish

function default
    for val in $argv
        if [ -n "$val" ]
            echo $val
            break
        end
    end
end

# Equivalent of "${RBLD_DIRECTORY:/etc/nixos}" in bash
set directory (default $RBLD_DIRECTORY "/etc/nixos")

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

# Adds the existence of any new files, but not their contents
git add -AN

# Rather than having to verify sudo during rebuild, we do it before. works as long as rebuild is <5 minutes
sudo -v || exit

nixos-rebuild switch \
    --use-remote-sudo --fast \
    --log-format internal-json \
    --flake $directory &| nom --json || exit 1
