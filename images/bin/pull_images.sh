#!/usr/bin/env bash
#
# pull_images.sh <destdir> <imagelist>
#
for image in $(cat $2)
do
  docker pull $image
  docker save $image -o "$1/${image//[\/\:]/__}.tar"
done