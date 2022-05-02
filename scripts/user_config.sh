#!/bin/bash

# Set sane defaults
set -eu -o pipefail

# Configure user account to work with DSV
# Disable lock screen:
dbus-launch --exit-with-session gsettings set org.gnome.desktop.screensaver lock-enabled false
# Disable screen locking: 
dbus-launch --exit-with-session gsettings set org.gnome.desktop.lockdown disable-lock-screen true
# Disable log out: 
dbus-launch --exit-with-session gsettings set org.gnome.desktop.lockdown disable-log-out true
# Disable idle lock screen: 
dbus-launch --exit-with-session gsettings set org.gnome.desktop.screensaver idle-activation-enabled false
# Disable idle lock screen: 
dbus-launch --exit-with-session gsettings set org.gnome.desktop.session idle-delay 0

# You may need to sudo su - <user> to get the env right if doing this as root

# Copy welcome message to desktop
cp /tmp/Welcome.md $HOME/Desktop/

# Configure VScode
code --install-extension ms-python.python