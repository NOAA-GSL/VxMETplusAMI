#!/bin/bash

# Set sane defaults
set -eu -o pipefail

# Install inspired by the MET Dockerfile here: https://github.com/dtcenter/MET/blob/main_v10.0/scripts/docker/Dockerfile
# MET prereqs
yum -y update
yum -y install file gcc gcc-gfortran gcc-c++ glibc.i686 libgcc.i686 \
                    libpng-devel jasper jasper-devel zlib zlib-devel cairo-devel \
                    freetype-devel epel-release hostname m4 make tar tcsh ksh \
                    time which wget flex flex-devel bison bison-devel unzip
yum -y install git g2clib-devel hdf5-devel.x86_64 gsl-devel
yum -y install gv ncview wgrib wgrib2 ImageMagick ps2pdf
yum -y install python3 python3-devel python3-pip
pip3 install --upgrade pip
python3 -m pip install numpy xarray netCDF4 # dateutil is pulled in by these dependencies

# MET installation
mkdir -p /opt/met/tar_files
if [ -f /tmp/install_met_env.centos_aws ]; then
    mv /tmp/install_met_env.centos_aws /opt/met/ && chmod +x /opt/met/install_met_env.centos_aws
else
    exit 1
fi
wget -P /opt/met https://raw.githubusercontent.com/dtcenter/MET/main_v10.1/scripts/installation/compile_MET_all.sh
chmod 775 /opt/met/compile_MET_all.sh
wget -qO - https://dtcenter.ucar.edu/dfiles/code/METplus/MET/installation/tar_files.tgz | tar -xz -C /opt/met
wget -P /opt/met/tar_files https://github.com/dtcenter/MET/releases/download/v10.1.0/met-10.1.0.20220314.tar.gz
# TODO - does this still work?
bash /opt/met/compile_MET_all.sh /opt/met/install_met_env.centos_aws
