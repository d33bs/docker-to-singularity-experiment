#!/bin/bash

rm ./image/source-docker-image.tar
rm ./image/target-singularity-image.sif

docker buildx create --name mybuilder
docker buildx use mybuilder

docker buildx build --platform linux/amd64 -f ./docker/Dockerfile.1.source-image -t source-docker-image . --load
docker save source-docker-image -o image/source-docker-image.tar

docker build --platform linux/arm64 -f docker/Dockerfile.2.build-singularity-image -t singularity-builder .
docker run --platform linux/arm64 -v $PWD/image:/image -it --privileged singularity-builder 

docker build --platform linux/arm64 -f docker/Dockerfile.3.run-singularity-image -t singularity-runner .
docker run --platform linux/arm64 -v $PWD/delivery:/delivery -v $PWD/image:/image -it --privileged singularity-runner 
