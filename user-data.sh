#!/bin/bash

# This script requires an instance with 4 GB of memory (like a t3.medium)

# Set sane defaults
set -eu -o pipefail

# Configure the desired user names here
user1=
user2=
# Configure the url path for the instance
dcvurl=

# Replace the DCV url
sed -i "s/#web-url-path=\"\/dcv\"/web-url-path=\"\/${NEWPATH}\"/" /etc/dcv/dcv.conf

chmod ugo+xr /tmp/install_metplus.sh 
chmod ugo+xr /tmp/install_miniconda.sh 
chmod ugo+xr /tmp/setup_conda_env.sh
chmod ugo+r  /tmp/environment.yml
chmod ugo+r  /tmp/Externals.cfg
chmod ugo+r  /tmp/Welcome.md

# Add management user
useradd ian.mcginnis
echo "ian.mcginnis ALL=(ALL) NOPASSWD: ALL">>/etc/sudoers.d/ian

# user1
usermod --login $user1 --move-home --home /home/$user1 user1
sudo -i -u $user1 bash -c "/tmp/install_metplus.sh; /tmp/install_miniconda.sh"
sudo -i -u $user1 bash -c "/tmp/setup_conda_env.sh"
sudo -i -u $user1 bash -c "/tmp/user_config.sh"
echo "$user1,$(sed -r 's:\.:\-:g' <<< $user1)" | sudo tee -a /etc/rc.d/init.d/dcvlist

# user2
usermod --login $user2 --move-home --home /home/$user2 user2
sudo -i -u $user2 bash -c "/tmp/install_metplus.sh; /tmp/install_miniconda.sh"
sudo -i -u $user2 bash -c "/tmp/setup_conda_env.sh"
sudo -i -u $user2 bash -c "/tmp/user_config.sh"
echo "$user2,$(sed -r 's:\.:\-:g' <<< $user2)" | sudo tee -a /etc/rc.d/init.d/dcvlist

echo "web-url-path=\"/$dcvurl\"" | sudo tee -a /etc/dcv/dcv.conf

service dcvserver restart
service dcvsession start
