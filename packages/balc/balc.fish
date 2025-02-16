#! /usr/bin/env fish

# The inputs we care about, split into a list
set INPUTS (echo $argv[1] | string split " ")

# For each input we're tracking, add its revision time
function sum_all_revisions
    set sum 0

    for input in $INPUTS
        set time (cat flake.lock | jq --arg input $input '.nodes.[$input].locked.lastModified')

        if [ $time = null ]
            echo "Input `$input` wasn't found in the flake.lock. Maybe you named it something else, or made a typo?"
            return 1
        end

        set sum (math "$sum + $time")
    end

    echo $sum # Returns value of sum
end

if ! set old_time (sum_all_revisions)
    # We return the error message from the function directly
    echo $old_time
    exit 1
end

nix flake update || exit

# We only check for errors once, and don't check again here. Should be fine (hopefully).
set new_time (sum_all_revisions)

# Logs for debugging
echo "Old time: $old_time"
echo "New time: $new_time"

if [ $old_time = $new_time ]
    echo "No important updates to flake.lock, so skipping rebuild"
    exit 1 # Tell unify we don't want to rebuild
end

exit 0 # We're okay with rebuilding
