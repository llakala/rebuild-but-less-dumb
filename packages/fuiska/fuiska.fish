#! /usr/bin/env fish

function default
    for val in $argv
        if [ $val != "" ]
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

# Fish can't parallelize functions, so we hack around it by storing a
# variable containing what would be in the function
set check_script '
set input $argv[1]
set full_contents $argv[2]
set data (echo $full_contents | jq -r --arg input "$input" \'.nodes[$input]\')

if test -z "$data"
    echo "No data found for input: $input"
    exit 1
end

# The input will never update if it points to a specific commit hash
set evergreen (echo $data | jq -r "if .original.rev then 0 else 1 end")

if [ $evergreen = 0 ]
    exit 0
end

set url (echo $data | jq -r "\"https://\" + .original.type + \".com/\" + .locked.owner + \"/\" + .original.repo + \".git\"")
set branch (echo $data | jq -r "if .original.ref then .original.ref else \"\" end")

set oldHash (echo $data | jq -r ".locked.rev")

if [ "$branch" = "" ]
    set newHash (git ls-remote $url "HEAD" | cut -f1)
else
    set newHash (git ls-remote --branches $url $branch | cut -f1)
end

if [ "$newHash" = "" ]
    echo "BAD, $input FAILED TO FETCH"
    exit 1
end

if [ "$oldHash" != "$newHash" ]
    echo "$input"
end
'

set inputs (echo $full_contents | jq -r ".nodes.root.inputs | keys[]")

echo "Inputs that need updating:"

# We parallelize via `fish -c` and `&`
for input in $inputs
    fish -c "$check_script" "$input" "$full_contents" &
end

wait
