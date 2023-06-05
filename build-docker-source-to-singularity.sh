#!/bin/bash

# set a platform var
export DOCKER_SINGULARITY_PLATFORM=linux/amd64

# remove existing files
rm ./delivery/test.txt
rm ./image/source-docker-image.tar.gz
rm ./image/target-singularity-image.sif*

# create a buildx builder
docker buildx create --name mybuilder
docker buildx use mybuilder

# build an image as per the platform
docker buildx build --platform $DOCKER_SINGULARITY_PLATFORM -f ./docker/Dockerfile.1.source-image -t source-docker-image . --load
docker save source-docker-image | gzip > image/source-docker-image.tar.gz

#load the docker image to test that the results work (in docker)
docker load -i image/source-docker-image.tar.gz
docker run --platform $DOCKER_SINGULARITY_PLATFORM -v $PWD/delivery:/delivery -it source-docker-image
if [[ ! -f delivery/test.txt ]] ; then
    echo 'File "delivery/test.txt" not available!'
    exit
fi
rm ./delivery/test.txt

# build the docker image as a singularity image
docker build --platform $DOCKER_SINGULARITY_PLATFORM -f docker/Dockerfile.2.build-singularity-image -t singularity-builder .
docker run --platform $DOCKER_SINGULARITY_PLATFORM -v $PWD/image:/image -it --privileged singularity-builder 

# try to run the singularity image, mapping the results through docker
# note: this appears to be broken for linux/amd64 running on apple silicone but otherwise works with arm64 platforms on the same
docker build --platform $DOCKER_SINGULARITY_PLATFORM -f docker/Dockerfile.3.run-singularity-image -t singularity-runner .
docker run --platform $DOCKER_SINGULARITY_PLATFORM -v $PWD/delivery:/delivery -v $PWD/image:/image -it --privileged singularity-runner 

# test that we found our expected results
if [[ ! -f delivery/test.txt ]] ; then
    echo 'File "delivery/test.txt" not available!'
    exit
fi

# package the singularity image for a release
tar -C ./image -czvf ./image/target-singularity-image.sif.tar.gz target-singularity-image.sif
