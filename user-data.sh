#!/bin/bash

# This script requires an instance with 4 GB of memory (like a t3.medium)

# Set sane defaults
set -eu -o pipefail

# Configure the desired user names here
user1=
user2=

# user1
sudo usermod --login $user1 --move-home --home /home/$user1 user1
sudo -i  -u $user1 bash -c "bash /tmp/install_metplus.sh; bash /tmp/install_miniconda.sh"
sudo -i  -u $user1 bash -c "bash /tmp/setup_conda_env.sh"

# user2
sudo usermod --login $user2 --move-home --home /home/$user2 user2
sudo -i  -u $user2 bash -c "bash /tmp/install_metplus.sh; bash /tmp/install_miniconda.sh"
sudo -i  -u $user2 bash -c "bash /tmp/setup_conda_env.sh"
