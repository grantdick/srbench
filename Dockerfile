################################################################################
FROM --platform=linux/amd64 mambaorg/micromamba:0.21.2 as build
# FROM continuumio/miniconda3 AS build
# Container for building the environment
# FROM condaforge/mambaforge:4.9.2-5 as conda
################################################################################
# Nvidia code ##################################################################
################################################################################
ENV PATH /usr/local/nvidia/bin/:$PATH
ENV LD_LIBRARY_PATH /usr/local/nvidia/lib:/usr/local/nvidia/lib64:$LD_LIBRARY_PATH
# Tell nvidia-docker the driver spec that we need as well as to
# use all available devices, which are mounted at /usr/local/nvidia.
# The LABEL supports an older version of nvidia-docker, the env
# variables a newer one.
ENV NVIDIA_VISIBLE_DEVICES all
ENV NVIDIA_DRIVER_CAPABILITIES compute,utility
LABEL com.nvidia.volumes.needed="nvidia_driver"
################################################################################

# Install base packages.
USER root

RUN apt update && apt install -y \
    default-jdk \
    bzip2 \
    ca-certificates \
    curl \
    git \
    wget \
    vim \
    jq && \
    rm -rf /var/lib/apt/lists/*

# Install env
################################################################################
FROM build as base
################################################################################
SHELL ["/bin/bash", "-c"]
# USER $MAMBA_USER
# WORKDIR /srbench/
COPY --chown=$MAMBA_USER:$MAMBA_USER environment.yml /tmp/environment.yml
# COPY environment.yml /tmp/environment.yml
# RUN micromamba create -y -p /venv/ -f /tmp/environment.yml \
#     && micromamba clean --all --yes
RUN micromamba create -y -f /tmp/environment.yml \
    && micromamba clean --all --yes
ENV CONDA_PREFIX $MAMBA_ROOT_PREFIX
ARG MAMBA_DOCKERFILE_ACTIVATE=1

# SHELL ["micromamba", "run", "-n", "srbench", "/bin/bash", "-c"]

# SHELL ["conda", "run", "-n", "srbench","/bin/bash", "-c"]
# WORKDIR /srbench/
COPY . .
RUN bash install.sh

##################################################
# these lines use conda-pack to shrink the image size
# https://pythonspeed.com/articles/conda-docker-image-size/
##################################################
# Install conda-pack:
# RUN conda install -n srbench -c anaconda conda
# RUN conda install -n srbench conda-pack
# Use conda-pack to create a standalone enviornment
# in /venv:
# ENV CONDA_EXE micromamba
# RUN env
# RUN conda list
# RUN conda-pack -n srbench -o /tmp/env.tar && \
#   mkdir /venv && \
#   cd /venv && \
#   tar xf /tmp/env.tar && \
#   rm /tmp/env.tar

# We've put venv in same path it'll be in final image,
# so now fix up paths:
# SHELL ["/bin/bash", "-c"]
# RUN /venv/bin/conda-unpack


# The runtime-stage image; we can use Debian as the
# base image since the Conda env also includes Python
# for us.
################################################################################
# FROM ubuntu:latest AS runtime
# Distroless for execution
# FROM gcr.io/distroless/base-debian10 as runtime
################################################################################
# Copy /venv from the previous stage:
# COPY --from=base /venv /venv
# COPY --from=base /usr/local/bin/_entrypoint.sh /usr/local/bin/
# ENTRYPOINT ["/usr/local/bin/_entrypoint.sh"]
# ENV PATH /venv/bin/:$PATH
# When image is run, run the code with the environment
# activated:
##################################################
# install SR methods with install.sh files
# COPY . /srbench/
# COPY --chown=$MAMBA_USER:$MAMBA_USER . /srbench/
# SHELL ["micromamba", "run", "-n", "srbench", "/bin/bash", "-c"]
# make the shell activate srbench
# SHELL ["/bin/bash","-c"]
# RUN source /venv/bin/activate
##################################################

