# README

## Installation

### Update Project Name

1. Rename `./PROJECT_NAME.code-workspace`.
2. Rename `./PROJECT_NAME` folder.
3. Edit `./manifest` file with new project name: `PYTHON_ENV_NAME=PROJECT_NAME`.
4. Edit `./setup.py` file with new project name and correct URL: `name="PROJECT_NAME"` and `url="https://github.com/USERNAME/PROJECT_NAME/"`.
5. Edit `./setup.cfg` file with new project name: `known_MYSELF=PROJECT_NAME`
6. Edit './hk3/main.py' file with new project name (in the import statements).

### Customize `./requirements.txt`

Add any dependencies, like pytorch, detectron2, pytorch_lightning, mmf, etc.

### Setup Python Environment

This uses Anaconda to create the package, and installs requirements from requirements.txt. The environment name is defined in the `./manifest` file.

```bash
cd scripts
./create_env.sh
```
