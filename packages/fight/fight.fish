#! /usr/bin/env fish
# We store this in a separate script from Fuiska, since Fish can't parallelize functions

set input $argv[1]
set full_contents $argv[2]

set data (echo $full_contents | jq -r --arg input $input '.nodes[$input]')

if [ -z "$data" ]
    echo "No data found for input: $input"
    exit 1
end

# The input will never update if it points to a specific commit hash
set evergreen (echo $data | jq -r "if .original.rev then 0 else 1 end")

if [ $evergreen = 0 ]
    exit 0
end

set url (echo $data | jq -r '"https://" + .original.type + ".com/" + .locked.owner + "/" + .original.repo + ".git"')
set branch (echo $data | jq -r 'if .original.ref then .original.ref else "" end')

set oldHash (echo $data | jq -r ".locked.rev")

if [ -z "$branch" ]
    set newHash (git ls-remote $url "HEAD" | cut -f1)
else
    set newHash (git ls-remote --branches $url $branch | cut -f1)

    if [ -z "$newHash" ] # What we assumed was a branch may have been a tag
        set newHash (git ls-remote --tags $url $branch | cut -f1)
    end

end

if [ -z "$newHash" ]
    echo "BAD, $input FAILED TO FETCH"
    exit 1
end

if [ $oldHash != $newHash ]
    echo $input
end
