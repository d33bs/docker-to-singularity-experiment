#!/bin/bash

# cd to scratch space
cd /scratch/alpine/$USER

# use acompile script to access further modules on alpine
acompile

# load singularity module
module load singularity/3.7.4

# download singularity image sif as tar.gz
wget https://github.com/d33bs/docker-to-singularity-experiment/releases/download/v0.0.1/target-singularity-image.sif.tar.gz

# extract image from archive
tar -zxvf target-singularity-image.sif.tar.gz

# run singularity, binding the local directory with the image file
singularity run --bind $PWD:/delivery target-singularity-image.sif
