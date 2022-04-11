#!/bin/bash

# Set sane defaults
set -eu -o pipefail

wget -P /tmp https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
bash /tmp/Miniconda3-latest-Linux-x86_64.sh -b -p $HOME/miniconda
rm /tmp/Miniconda3-latest-Linux-x86_64.sh
source $HOME/miniconda/bin/activate && conda init bash
