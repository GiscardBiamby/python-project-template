#!/bin/bash
set -Ee -o pipefail
# 'inherit_errexit' is Bash 4.4+. Use '|| true' to avoid failure on older Bash versions (e.g. macOS default).
shopt -s inherit_errexit 2>/dev/null || true

# Get the directory of this script so that we can reference paths correctly no matter which folder
# the script was launched from:
SCRIPTS_DIR="$(builtin cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJ_ROOT="$(realpath "${SCRIPTS_DIR}"/../)"

# * Export all variabes from manifest file:
set -a
# shellcheck disable=SC1091
source "${PROJ_ROOT}/manifest"
set +a

# * =======================
# * Config (override via env)
# * =======================
PY_SPEC="${PY_SPEC:-python=${PYTHON_VERSION}}"      # used when YML is empty
# YML="${YML:-}"                         # path to environment.yml (optional)
YML="$(realpath "${PROJ_ROOT}/environment.yml")"  # make absolute if given
PACKAGES="${PACKAGES:-}"               # extra specs (e.g., "numpy pandas")
CHANNELS="${CHANNELS:-}"               # e.g., "conda-forge" or "conda-forge,defaults"

echo ""
echo "========================================================================"
echo "create_env.sh"
echo "PYTHON_ENV_NAME: ${PYTHON_ENV_NAME}"
echo "SCRIPTS_DIR: ${SCRIPTS_DIR}"
echo "PROJ_ROOT: ${PROJ_ROOT}"
echo "CONDA_DIR: ${CONDA_DIR}"
echo "YML: ${YML}"
echo "PACKAGES: ${PACKAGES}"
echo "CHANNELS: ${CHANNELS}"

die() {
    echo "ERROR: $*" >&2
    exit 1
}
note() { echo "NOTE: $*" >&2; }

[[ -n "$PYTHON_ENV_NAME" ]] || die "PYTHON_ENV_NAME must not be empty"
[[ "$PYTHON_ENV_NAME" != "base" && "$PYTHON_ENV_NAME" != "root" ]] || die "Refusing to operate on '$PYTHON_ENV_NAME'"

# -----------------------
# Pick a package manager
# -----------------------
ACT=""           # micromamba | mamba | conda
RUNNER=""        # used for 'run -n'
if command -v micromamba >/dev/null 2>&1; then
    ACT="micromamba"
    RUNNER="micromamba"
elif command -v mamba >/dev/null 2>&1; then
    ACT="mamba"
    RUNNER="mamba"
elif command -v conda >/dev/null 2>&1; then
    ACT="conda"
    RUNNER="conda"
else
    die "No micromamba/mamba/conda found in PATH."
fi

# Helper: build channel flags (supports comma- or space-separated)
IFS=', ' read -r -a _chs <<<"$CHANNELS"
CH_FLAGS=()
for ch in "${_chs[@]}"; do
    [[ -n "$ch" ]] && CH_FLAGS+=(-c "$ch")
done
unset _chs

# -----------------------
# Utility helpers
# -----------------------
env_exists() {
    "$ACT" env list 2>/dev/null | awk '{print $1}' | grep -qx "$PYTHON_ENV_NAME"
}

# Where this env likely lives on disk (multiple candidates)
candidate_env_dirs() {
    local cand=()

    # Tool-specific defaults
    if [[ "$ACT" == "micromamba" ]]; then
        local root="${MAMBA_ROOT_PREFIX:-$HOME/micromamba}"
        cand+=("$root/envs/$PYTHON_ENV_NAME")
    else
        # conda/mamba
        local base=""
        base="$("$ACT" info --base 2>/dev/null || true)"
        [[ -n "$base" ]] && cand+=("$base/envs/$PYTHON_ENV_NAME")
    fi

    # Common roots (catch-all)
    cand+=("$HOME/miniforge3/envs/$PYTHON_ENV_NAME"
          "$HOME/mambaforge/envs/$PYTHON_ENV_NAME"
          "$HOME/miniconda3/envs/$PYTHON_ENV_NAME"
          "$HOME/anaconda3/envs/$PYTHON_ENV_NAME"
          "/opt/conda/envs/$PYTHON_ENV_NAME"
          "$HOME/.conda/envs/$PYTHON_ENV_NAME"
          "$HOME/.micromamba/envs/$PYTHON_ENV_NAME")

    # De-duplicate & print
    awk '!seen[$0]++' < <(printf "%s\n" "${cand[@]}")
}

# Guard-rail rm -rf (only inside .../envs/PYTHON_ENV_NAME)
safe_rm_rf() {
    local path="$1"
    # Must exist
    [[ -e "$path" ]] || return 0
    # Must be a directory
    [[ -d "$path" ]] || {
        note "Skipping non-directory: $path"
        return 0
    }
    # Must contain '/envs/' and end with "/$PYTHON_ENV_NAME"
    [[ "$path" == *"/envs/$PYTHON_ENV_NAME" ]] || {
        note "Skip (doesn't match /envs/$PYTHON_ENV_NAME): $path"
        return 0
    }
    # Refuse suspiciously short paths
    local depth
    depth="$(tr -dc '/' <<<"$path" | wc -c | tr -d ' ')"
    ((depth >= 3)) || {
        note "Skip (path too shallow): $path"
        return 0
    }

    echo "Force-deleting: $path"
    rm -rf --one-file-system -- "$path"
}

# Try to deactivate if the target env is currently active
maybe_deactivate() {
    echo "CONDA_PREFIX: ${CONDA_PREFIX}"

    # We cannot reliably deactivate the parent shell's environment from this script.
    # If the target environment is active, we must abort.
    local active_prefix="${CONDA_PREFIX:-}"
    if [[ -n "$active_prefix" && "$active_prefix" == *"/envs/$PYTHON_ENV_NAME" ]]; then
        die "Environment '$PYTHON_ENV_NAME' is currently ACTIVE. Please run 'conda deactivate' (or 'mamba deactivate') in your terminal before running this script."
    fi
}

# Remove via tool (best effort)
tool_remove_env() {
    echo "Removing environment '$PYTHON_ENV_NAME' via $ACT (best effort)..."
    if [[ "$ACT" == "micromamba" ]]; then
        "$ACT" remove -y -n "$PYTHON_ENV_NAME" --all || true
    else
        "$ACT" env remove -y -n "$PYTHON_ENV_NAME" || true
    fi
}

# Full delete flow
full_delete_env_if_exists() {
    if env_exists; then
        echo "Environment '$PYTHON_ENV_NAME' appears to exist."
        maybe_deactivate
        tool_remove_env
    else
        note "Environment '$PYTHON_ENV_NAME' not listed by $ACT; proceeding to hard cleanup just in case."
    fi

    # Hard cleanup across candidate locations
    while IFS= read -r p; do
        safe_rm_rf "$p"
    done < <(candidate_env_dirs)
}

list_env() { "$RUNNER" list -n "$PYTHON_ENV_NAME" "$@"; }
info_env() { "$RUNNER" info -n "$PYTHON_ENV_NAME" "$@"; }

full_delete_env_if_exists

echo "Creating fresh environment '$PYTHON_ENV_NAME' with $ACT..."
if [[ -n "$YML" ]]; then
    [[ -r "$YML" ]] || die "YML not readable: $YML"
    if [[ "$ACT" == "micromamba" ]]; then
        "$ACT" create -y -n "$PYTHON_ENV_NAME" "${CH_FLAGS[@]}" -f "$YML"
    else
        # conda/mamba ignore channels in the command line when suing -f, so put those in the
        # `environment.yaml` if you need them.
        "$ACT" env create -y -n "$PYTHON_ENV_NAME" -f "$YML"
    fi
else
    "$ACT" create -y -n "$PYTHON_ENV_NAME" "${CH_FLAGS[@]}" "$PY_SPEC" "$PACKAGES" || true
fi

run_in_env()  {

    # Prefer an array for the runner to avoid word-splitting
    local runner=("${RUNNER:?}")

    echo "[$PYTHON_ENV_NAME] Running:"
    echo "+ ${runner[*]} run -n $PYTHON_ENV_NAME -- $*"
    # Usage: run_in_env <cmd> [args...]
    "${runner[@]}" run -n "$PYTHON_ENV_NAME" "$@"
}

echo ""
echo "Environment: $PYTHON_ENV_NAME"
echo "RUnner: ${RUNNER}"
echo "RUNNER raw: [$RUNNER]"
command -v "${RUNNER%% *}" || true # shows if it's an alias/function
run_in_env python -V
run_in_env pip -V

# Example: run your program(s)
# run_in_env python your_script.py

echo ""
echo "DIAGNOSTICS: Python environment details:"
run_in_env python - <<'PY'
import sys, sysconfig, platform
print("Python:", platform.python_version())
print("Prefix:", sys.prefix)
print("Executable:", sys.executable)
print("Site-packages:", sysconfig.get_paths().get("purelib"))
PY

echo ""
echo "Installing the main package in editable mode"
rm -rf "${PROJ_ROOT}/build" "${PROJ_ROOT}/dist" "${PROJ_ROOT}/__pycache__" || true
run_in_env pip install --no-deps -e . \
    --config-settings editable_mode=compat \
    --no-build-isolation \
    -c "${PROJ_ROOT}/constraints.txt"

# Make the python environment available for running jupyter kernels:
run_in_env python -m ipykernel install --user --name="${PYTHON_ENV_NAME}"
# (Optional) make sure Lab can build prebuilt bits if needed — JL4 usually skips rebuilds
run_in_env jupyter lab build --dev-build=False --minimize=False >/dev/null 2>&1 || true

## * Custom dependencies

# * Install external library code:
pushd "${PROJ_ROOT}/lib"

# echo ""
# echo "=================================================================================="
# echo "Installing custom dep: sahi"
# pushd "${PROJ_ROOT}/lib/sahi"
# # Use strict mode to allow vscode intellisense/Pylance to find this editable install of sahi:
# # https://stackoverflow.com/questions/76213501/python-packages-imported-in-editable-mode-cant-be-resolved-by-pylance-in-vscode
# # https://setuptools.pypa.io/en/latest/userguide/development_mode.html#strict-editable-installs
# pip install -e . --config-settings editable_mode=strict -c "${PROJ_ROOT}/constraints.txt"
# popd

# echo ""
# echo "=================================================================================="
# echo "Installing custom dep: mmdetection"
# pushd "${PROJ_ROOT}/lib/mmdetection"
# # https://mmcv.readthedocs.io/en/2.x/get_started/installation.html
# pip install mmcv==2.2.0 \
#     -f https://download.openmmlab.com/mmcv/dist/cu121/torch2.4/index.html \
#     -c "${PROJ_ROOT}/constraints.txt" \
#     --no-cache-dir
# # Use editable_mode=compat to avoid errors related to not being able to find torch during install
# # (due to build isolation in newer versions of pip).
# pip install -v --no-build-isolation \
#     --config-settings editable_mode=compat \
#     -e . \
#     -c "${PROJ_ROOT}/constraints.txt"
# popd

popd

## * Post-install fixes:

# # * Replace pillow with pillow-simd for faster image processing:
# run_in_env pip uninstall -y pillow pillow-simd PIL pil
# run_in_env pip install --no-deps --no-binary=:all: --force-reinstall \
#     pillow-simd \
#     -c "${PROJ_ROOT}/constraints.txt"

## *
## * We are done, show the python environment:
echo ""
echo "=================================================================================="
echo "Listing conda environments..."
list_env

echo ""
echo "=================================================================================="
echo "Listing environment info..."
info_env

echo ""
echo "=================================================================================="
echo "Listing conda environment..."
run_in_env $ACT list

echo ""
echo "=================================================================================="
echo "Listing pip environment..."
run_in_env pip list

echo ""
echo "=================================================================================="
echo "Check torch.__version__:"
run_in_env python -c "import torch; print('torch.__version__: ', torch.__version__, 'cuda:', torch.version.cuda)"
echo "Check torch.cuda:"
run_in_env python -c "import torch; print('torch.cuda.is_available: ', torch.cuda.is_available())"

echo ""
echo "=================================================================================="
echo "Check opencv"
run_in_env python - <<'EOF'
import torch, sys
print("torch:", torch.__version__, "cuda:", torch.version.cuda)
try:
    import cv2
    print("opencv:", cv2.__version__)
except Exception as e:
    print("opencv: not present or failed:", e)
EOF

# echo ""
# echo "=================================================================================="
# echo "Check pillow-simd"
# run_in_env python - <<'PY'
# import PIL, PIL.Image as I
# print("PIL from:", getattr(PIL, "__file__", None))
# print("Pillow-SIMD OK, version:", getattr(PIL, "__version__", None))
# print("Image module:", I)
# PY

echo "Done!!!!!!!!!!!!!!!!"
