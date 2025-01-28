#! /usr/bin/env fish
# We store this in a separate script from Fuiska, since Fish can't parallelize functions

set input $argv[1]
set full_contents $argv[2]
set api $argv[3] # If it's set to "false", don't fetch from API

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
set branch (echo $data | jq -r 'if .original.ref then .original.ref else "" end')

set host (echo $data | jq -r ".original.type")

if [ "$api" = false ]
    set host none # Use the generic git fetcher
end

switch $host

    case github # https://docs.github.com/en/rest/commits/commits?apiVersion=2022-11-28
        set url (echo $data | jq -r '"https://api.github.com/repos/" + .locked.owner + "/" + .original.repo + "/commits/" + if .original.ref then .original.ref else "HEAD" end')
        set newHash (curl --silent $url | jq -r ".sha")

    case gitlab # https://docs.gitlab.com/ee/api/commits.html
        set url (echo $data | jq -r '"https://gitlab.com/api/v4/projects/" + .locked.owner + "%2F" + .original.repo + "/repository/commits/" + if .original.ref then .original.ref else "HEAD" end')
        set newHash (curl --silent $url | jq -r ".id")

    case '*' # Any other forge
        # We make URL branchless here, and pass it in as an argument
        set url (echo $data | jq -r '"https://" + .original.type + ".com/" + .locked.owner + "/" + .original.repo + ".git"')

        if [ -z "$branch" ]
            set newHash (git ls-remote $url "HEAD" | cut -f1)
        else
            set newHash (git ls-remote --branches $url $branch | cut -f1)
        end

        if [ -z "$newHash" ] # What we assumed was a branch may have been a tag
            set newHash (git ls-remote --tags $url $branch | cut -f1)
        end

end

if [ -z "$newHash" ]
    echo "$input failed to fetch a commit hash with url $url"
    exit 1
end


if [ $oldHash != $newHash ]
    set epoch (echo $data | jq -r ".locked.lastModified") # Time of last revision in Epoch time

    set then (date --date "@$epoch" --iso-8601=hours)
    set now (date --date now --iso-8601=hours)

    set days (datediff $then $now -f "%d")
    set hours (datediff $then $now -f "%h")

    if [ $days = 0 ]
        echo "$input (from $hours hours ago)"
    else
        echo "$input (from $days days ago)"
    end
end
