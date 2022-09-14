# README

## Installation

### Update Project Name

1. Rename `./PROJECT_NAME.code-workspace`.
2. Rename `./PROJECT_NAME` folder.
3. Edit `./manifest` file with new project name: `PYTHON_ENV_NAME=PROJECT_NAME`.
4. Edit `./setup.py` file with new project name and correct URL: `name="PROJECT_NAME"` and `url="https://github.com/USERNAME/PROJECT_NAME/"`.
5. Edit `./setup.cfg` file with new project name: `known_MYSELF=PROJECT_NAME`
6. Edit `./PROJECT_NAME/main.py` file with new project name (in the import statements).

### Customize `./requirements.txt`

Add any dependencies, like pytorch, detectron2, pytorch_lightning, mmf, etc.

### Setup Python Environment

This uses mamba (a drop-in replacement for Anaconda) to create the package, and installs requirements from requirements.txt. The environment name is defined in the `./manifest` file.

```bash
cd scripts
./create_env.sh
```

### Update isort path

Update `.vscode/settings.json`, change the setting `python.sortImports.path` to the path of isort that is specific to your conda environment. You can find this out by running `conda activate $PYTHON_ENV_NAME && which isort`.

## Optional / Advanced

Improve vscode performance by excluding folders/files from python lanugage server indexing. Do this by updating the excludes in `pyrightconfig.json`.
