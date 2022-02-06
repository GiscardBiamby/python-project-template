from argparse import ArgumentParser
from pathlib import Path
from typing import List
import torch.nn as nn
import wandb

from PROJECT_NAME.consts import PROJECT_ROOT


def main(args) -> None:
    print("Hello")


if __name__ == "__main__":
    parser = ArgumentParser()
    parser.add_argument("--lr", type=float, default=1e-4)
    parser.add_argument("--num_workers", type=int, default=0)
    parser.add_argument("--batch_size", type=int, default=12)
    parser.add_argument("--img_dir", type=Path, default=(PROJECT_ROOT / "datasets/images"))
    args = parser.parse_args()
    main(args)
