#!/bin/bash
echo "env_check"
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

echo ""
echo "========================================================================"
echo "create_env.sh"
echo "PYTHON_ENV_NAME: ${PYTHON_ENV_NAME}"
echo "SCRIPTS_DIR: ${SCRIPTS_DIR}"
echo "PROJ_ROOT: ${PROJ_ROOT}"
echo "CONDA_DIR: ${CONDA_DIR}"
echo "PYTHON_ENV_NAME: ${PYTHON_ENV_NAME}"

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
# * Activate conda environment:
conda activate "${PYTHON_ENV_NAME}"

echo ""
echo "=================================================================================="
conda info --envs

echo ""
echo "=================================================================================="
conda list

echo ""
echo "=================================================================================="
echo "Check torch.cuda:"
python -c "import torch; print('torch.cuda.is_available: ', torch.cuda.is_available())"

# echo ""
# echo "=================================================================================="
# echo "Check mmdet import"
# python -c "import mmdet; print('mmdet.__version__: ', mmdet.__version__)"

echo "Done!"
