#!/bin/bash

# remove existing files
rm ./delivery/test.txt
rm ./image/source-docker-image.tar.gz
rm ./image/target-singularity-image.sif*

# create a buildx builder
docker buildx create --name mybuilder
docker buildx use mybuilder

# build an image as per the platform
docker buildx build --platform linux/arm64 -f ./docker/Dockerfile.1.source-image -t source-docker-image . --load
docker save source-docker-image | gzip > image/source-docker-image.tar.gz

#load the docker image to test that the results work (in docker)
docker load -i image/source-docker-image.tar.gz
docker run -v $PWD/delivery:/delivery -it source-docker-image
if [[ ! -f delivery/test.txt ]] ; then
    echo 'File "delivery/test.txt" not available!'
    exit
fi
rm ./delivery/test.txt

# build the docker image as a singularity image
docker build --platform linux/arm64 -f docker/Dockerfile.2.build-singularity-image -t singularity-builder .
docker run --platform linux/arm64 -v $PWD/image:/image -it --privileged singularity-builder 

# try to run the singularity image, mapping the results through docker
docker build --platform linux/arm64 -f docker/Dockerfile.3.run-singularity-image -t singularity-runner .
docker run --platform linux/arm64 -v $PWD/delivery:/delivery -v $PWD/image:/image -it --privileged singularity-runner 

# test that we found our expected results
if [[ ! -f delivery/test.txt ]] ; then
    echo 'File "delivery/test.txt" not available!'
    exit
fi

# package the singularity image for a release
tar czvf image/target-singularity-image.sif.tar.gz image/target-singularity-image.sif
