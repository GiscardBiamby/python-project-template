#!/bin/bash
set -e

# Get the directory of this script so that we can reference paths correctly no matter which folder
# the script was launched from:
SCRIPTS_DIR="$(dirname -- "$(readlink -f -- "$0")")"
source "${SCRIPTS_DIR}/../manifest"

# If you don't use anaconda  you can replace the relevant environment creation and activation lines
# with pyenv or whatever system you use to manage python environments.
# source ~/anaconda3/etc/profile.d/conda.sh
source ~/mambaforge/etc/profile.d/conda.sh
source ~/mambaforge/etc/profile.d/mamba.sh
source "${SCRIPTS_DIR}/../manifest"

ENV_NAME=$PYTHON_ENV_NAME
echo "ENV_NAME: ${ENV_NAME}"

## Remove env if exists:
mamba deactivate && mamba env remove --name "${ENV_NAME}"
rm -rf "${HOME}/mambaforge/envs/${ENV_NAME}"

# Create env:
mamba create --name "${ENV_NAME}" python=="${PYTHON_VERSION}" -y

mamba activate "${ENV_NAME}"
echo "Current environment: "
mamba info --envs | grep "*"

##
## Base dependencies
echo "Installing requirements..."
echo "Installing pytorch"
# mamba install -y pytorch==1.9.0 torchvision==0.10.0 torchaudio==0.9.0 cudatoolkit=11.3 -c pytorch -c conda-forge

# If you have trouble installing torch, i.e, package manager installs cpu version, or wrong version,
# might need to specify channel version, and cuda using this method. Additionally, it could help to
# search the package repositories to see what packages and build versions are available, using:
#   `conda search "pytorch[build=*cuda11.1*,version=1.8.1,channel=pytorch]"`
#
# mamba install \
#     "pytorch[build=*cuda11.1*,version=1.8.1,channel=pytorch]" \
#     "torchvision[build=*_cu111*,version=0.9.1,channel=pytorch]" \
#     cudatoolkit=11.1 \
#     -c pytorch -c conda-forge -c anaconda -y

mamba install -y pytorch==1.12.1 torchvision cudatoolkit=11.6 cudnn -c pytorch
pip install --upgrade pip -c "${SCRIPTS_DIR}/../constraints.txt"
pip install -r "${SCRIPTS_DIR}/../requirements.txt" -c "${SCRIPTS_DIR}/../constraints.txt"

# Make the python environment available for running jupyter kernels:
python -m ipykernel install --user --name="${ENV_NAME}"
# Install jupyter extensions
jupyter contrib nbextension install --user

## Custom dependencies
# Move to project root
pushd "${SCRIPTS_DIR}/.."
pip install -e . -c "${SCRIPTS_DIR}/../constraints.txt"

# # ## Object Detection Framework(s):
# pip install mmcv-full -f https://download.openmmlab.com/mmcv/dist/cu113/1.10.1/index.html -c ../constraints.txt
# pip install mmdet -c ../constraints.txt
# # pip install icevision[all]

# # Install external library code:
# pushd ../lib/

# # Install icevision (https://github.com/airctic/icevision):
# git clone git@github.com:GiscardBiamby/icevision.git
# pushd icevision
# pip install -e .[all,dev] -c ../../constraints.txt
# popd

# # Install customized version of pycocotools (https://github.com/GiscardBiamby/cocobetter):
# git clone git@github.com:GiscardBiamby/cocobetter.git
# pushd ./cocobetter/PythonAPI
# pip install -e . -c ../../../constraints.txt
# popd

# popd

# We are done, show the python environment:
mamba list
echo "Done!"
