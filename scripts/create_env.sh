#!/bin/bash
set -e

# Get the directory of this script so that we can reference paths correctly no matter which folder
# the script was launched from:
SCRIPTS_DIR="$(builtin cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJ_ROOT="$(realpath "${SCRIPTS_DIR}"/../)"

# * Export all variabes from manifest file:
set -a
# shellcheck disable=SC1091
source "${PROJ_ROOT}/manifest"
set +a
ENV_NAME=$PYTHON_ENV_NAME

echo ""
echo "========================================================================"
echo "create_env.sh"
echo "ENV_NAME: ${ENV_NAME}"
echo "SCRIPTS_DIR: ${SCRIPTS_DIR}"
echo "PROJ_ROOT: ${PROJ_ROOT}"
echo "CONDA_DIR: ${CONDA_DIR}"

# * Load conda/mamba
if [ -d ~/anaconda3/etc/profile.d ]; then
    source ~/anaconda3/etc/profile.d/conda.sh
elif [ -d /opt/miniconda-latest/etc/profile.d ]; then
    source /opt/miniconda-latest/etc/profile.d/conda.sh
elif [ -d ~/miniconda/etc/profile.d ]; then
    source ~/miniconda/etc/profile.d/conda.sh
elif [ -d ~/mambaforge/etc/profile.d ]; then
    source ~/mambaforge/etc/profile.d/conda.sh
    source ~/mambaforge/etc/profile.d/mamba.sh
else
    echo "ERROR, no conda installation found"
    exit 1
fi

# * Remove env if exists:
set +e
CONDA_FN="conda" # set this to "conda" if you are using conda/miniconda
if [ -d "${HOME}/anaconda3/envs/${ENV_NAME}" ]; then
    $CONDA_FN deactivate && conda env remove --name "${ENV_NAME}"
    rm -rf "${HOME}/anaconda3/envs/${ENV_NAME}"
elif [ -d "/opt/miniconda-latest/envs/${ENV_NAME}" ]; then
    $CONDA_FN deactivate && conda env remove --name "${ENV_NAME}"
    rm -rf "${HOME}/miniconda/envs/${ENV_NAME}"
elif [ -d "${HOME}/miniconda/envs/${ENV_NAME}" ]; then
    $CONDA_FN deactivate && conda env remove --name "${ENV_NAME}"
    rm -rf "${HOME}/miniconda/envs/${ENV_NAME}"
elif [ -d "${HOME}/mambaforge/envs/${ENV_NAME}" ]; then
    CONDA_FN="mamba"
    $CONDA_FN deactivate && mamba env remove --name "${ENV_NAME}"
    rm -rf "${HOME}/mambaforge/envs/${ENV_NAME}"
fi
set -e

# Create env:
$CONDA_FN create --name "${ENV_NAME}" python=="${PYTHON_VERSION}" -y
$CONDA_FN activate "${ENV_NAME}"
echo "Current environment: "
$CONDA_FN info --envs | grep "*"

##
## Base dependencies
echo "Installing requirements..."
echo "Installing pytorch"
# $CONDA_FN install -y pytorch==1.9.0 torchvision==0.10.0 torchaudio==0.9.0 cudatoolkit=11.3 -c pytorch -c conda-forge

# If you have trouble installing torch, i.e, package manager installs cpu version, or wrong version,
# might need to specify channel version, and cuda using this method. Additionally, it could help to
# search the package repositories to see what packages and build versions are available, using:
#   `conda search "pytorch[build=*cuda11.1*,version=1.8.1,channel=pytorch]"`
#
# $CONDA_FN install \
#     "pytorch[build=*cuda11.1*,version=1.8.1,channel=pytorch]" \
#     "torchvision[build=*_cu111*,version=0.9.1,channel=pytorch]" \
#     cudatoolkit=11.1 \
#     -c pytorch -c conda-forge -c anaconda -y

# $CONDA_FN install -y pytorch==1.12.1 torchvision cudatoolkit=11.6 cudnn -c pytorch
# pip install --upgrade pip setuptools wheel -c "${SCRIPTS_DIR}/../constraints.txt"
# pip install -r "${SCRIPTS_DIR}/../requirements.txt" -c "${SCRIPTS_DIR}/../constraints.txt"

$CONDA_FN install \
    "pytorch[build=py3.11_cuda11.7_cudnn8.5.0_0,channel=pytorch,version=2.0.1]" \
    cudatoolkit==11.7 \
    pytorch-cuda==11.7 \
    torchvision==0.15.2 \
    -c pytorch -c nvidia -c conda-forge -y
pip install --upgrade pip setuptools==69.5.1 wheel -c "${PROJ_ROOT}/constraints.txt"
pip install -r "${SCRIPTS_DIR}/../requirements.txt" -c "${PROJ_ROOT}/constraints.txt"

# * Make the python environment available for running jupyter kernels:
python -m ipykernel install --user --name="${ENV_NAME}"

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
echo ""
echo "=================================================================================="
$CONDA_FN list

echo ""
echo "=================================================================================="
echo "Check torch.cuda:"
python -c "import torch; print('torch.cuda.is_available: ', torch.cuda.is_available())"

# echo ""
# echo "=================================================================================="
# echo "Check mmdet import"
# python -c "import mmdet; print('mmdet.__version__: ', mmdet.__version__)"

echo "Done!"
