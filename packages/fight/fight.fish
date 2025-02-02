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

set oldHash (echo $data | jq -r ".locked.rev")
set ref (echo $data | jq -r 'if .original.ref then .original.ref else "" end') # Either a branch or a tag

set host (echo $data | jq -r ".original.type")

switch $host

    case tarball
        echo "WARNING: skipping input $input, as it's currently unparseable"
        exit 0

    case '*'
        # We make URL point to generic repo, and pass ref in as an argument
        set url (echo $data | jq -r '"https://" + .original.type + ".com/" + .locked.owner + "/" + .original.repo + ".git"')

        if [ -z "$ref" ]
            set newHash (git ls-remote $url "HEAD" | cut -f1)
        else
            set newHash (git ls-remote --branches $url $ref | cut -f1)
        end

        # What we assumed was a branch may have been a tag
        # We use ^{} to get the revision of the latest commit, not just the tag
        if [ -z "$newHash" ]
            set newHash (git ls-remote --tags $url "$ref^{}" | cut -f1)
        end

end

if [ -z "$newHash" ]
    echo "$input failed to fetch a commit hash with url $url"
    exit 1
end


if [ $oldHash != $newHash ]
    echo $input
end
