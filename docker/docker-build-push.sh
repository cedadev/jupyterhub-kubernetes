#! /bin/bash
#
# Usage: ./docker-build-push.sh (--no-cache) <dir> <remote prefix>
#

if [ "$#" -eq 3 ]; then
    cacheflag=$1
    dir=$2
    prefix=$3
else
    cacheflag=""
    dir=$1
    prefix=$2
fi

name=$(basename "$dir")
remote_name="$prefix/$name"

container=$(docker build -q "$cacheflag" "$dir")
docker tag "$container" "$name"
docker tag "$container" "$remote_name"
docker push "$remote_name"
