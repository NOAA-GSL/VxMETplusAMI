#!/bin/bash

# Set sane defaults
set -eu -o pipefail

# Set up conda metplus environment
cp /tmp/environment.yml $HOME/METplus/environment.yml
conda env create -f $HOME/METplus/environment.yml
# Tell MET to use miniconda Python
echo "export MET_PYTHON_EXE=$(which python)" >> $HOME/.bashrc
# Put MET & METplus on PATH
echo "export PATH=/opt/met/bin:$HOME/METplus/ush:$PATH" >> $HOME/.bashrc
# Activate conda env in user's .bashrc
echo "conda activate metplus-hackathon" >> $HOME/.bashrc
