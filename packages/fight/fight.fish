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

    case github gitlab git
        # We make URL point to generic repo, and pass ref in as an argument
        set url (echo $data | jq -r '"https://" + .original.type + ".com/" + .locked.owner + "/" + .original.repo + ".git"')

    case tarball
        # Flakes provide the direct tarball URL, but it's pointing to a tarball,
        # which we can't query without downloading.
        # Instead, we check if the URL looks something like:
        # `web.site/$1/$2/archive/$3.tar.gz'
        # If so, we can try ls-remote on it
        set tarballUrl (echo $data | jq -r '.original.url')
        set regexPattern '(https?:\/(?:\/[^\/]+){3})\/(?:archive|releases\/download)\/(?:refs\/tags\/)?([^\/]+)(?:\/[^\/]+)?(?:\.tar\.gz|\.zip|\.tar\.xz)'

        if ! echo $tarballUrl | rg -q --pcre2 $regexPattern # URL doesn't match
            echo "WARNING: skipping input $input of type tarball, as it can't be automatically reconstructed into a repo link"
            exit 0
        end

        set url (echo $tarballUrl | rg -N --color=never --pcre2 $regexPattern --replace '$1')
        set ref (echo $tarballUrl | rg -N --color=never --pcre2 $regexPattern --replace '$2')

        # Check if the ref is a specific commit, which can't be checked by ls-remote
        # Commits should be evergeen, skip it and move on
        if [ (echo -n $ref | wc -c) = 40 ]
            exit 0
        end


    case '*'
        echo "WARNING: skipping input $input of type $host, as it's currently unparseable"
        exit 0

end

if [ -z "$ref" ] # If we don't point to a specific tag or branch
    set newHash (git ls-remote $url "HEAD" | cut -f1)

# Check both branches AND tags. We check for both the normal ref and the unpeeled ref.
# We need to do this because using `*` results in the branch `nixos-unstable*` also
# matching `nixos-unstable-small`. Unpeeling the ref will do nothing for branches, but
# it lets annotated tags work properly. If the tag was annotated, we'll get two lines
# of output, one for the lightweight, and one for the annotated - which Fish turns
# into a list of length 2. Lightweight and annotated tags will be in a list of length 1.
# We then access the last element of the list, so if the ref was an annotated tag, we
# grab the right part, but lightweight tags and branches still work like normal.
else
    # Nix doesn't unpeel tarball refs, so we don't either to compare with the revision it stores
    if [ $host != "tarball" ]
      set ref $ref $ref^{}
    end

    set temp (git ls-remote --branches --tags $url $ref | cut -f1)
    set newHash $temp[-1]
end

if [ -z "$newHash" ]
    echo "ERROR: $input failed to fetch a commit hash with url `$url` and ref `$ref`"
    exit 1
end


if [ $oldHash != $newHash ]
    echo $input
end
