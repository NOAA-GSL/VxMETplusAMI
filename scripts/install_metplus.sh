#!/bin/bash

# Set sane defaults
set -eu -o pipefail

git clone https://github.com/dtcenter/METplus
# Copy our patched Externals.cfg into place
if [ -f /tmp/Externals.cfg ]; then
    cp /tmp/Externals.cfg $HOME/METplus/build_components/Externals.cfg
else
    exit 1
fi
# Update the defaults.conf with correct locations
sed -i 's:MET_INSTALL_DIR = /path/to:MET_INSTALL_DIR = /opt/met:g' $HOME/METplus/parm/metplus_config/defaults.conf
sed -i 's:INPUT_BASE = /path/to:INPUT_BASE = /metplus-data:g' $HOME/METplus/parm/metplus_config/defaults.conf
sed -i 's:OUTPUT_BASE = /path/to:OUTPUT_BASE = {ENV[HOME]}/metplus-output:g' $HOME/METplus/parm/metplus_config/defaults.conf

cd METplus && manage_externals/checkout_externals -e build_components/Externals.cfg
mkdir $HOME/metplus-output

echo "export PYTHONPATH=$HOME/METcalcpy:$HOME/METdatadb:$HOME/METplotpy" >> $HOME/.bashrc