#!/usr/bin/env bash
#
# Copied into container and run from Dockerfile
#
for image in $(</tmp/preload_images.txt); do
  echo "preloading image: $image"
  ctr129 -n moby images import --no-unpack "/tmp/images/${image//[\/\:]/__}.tar"
done
