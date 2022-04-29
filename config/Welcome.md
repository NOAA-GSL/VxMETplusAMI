# METplus Hackathon Welcome

On behalf of GMU, NOAA's GSL, & NCAR's DTC - welcome and thanks for participating in the METplus Hackathon! We're glad you're here. This document is intended to help orient you to the METplus instance we've put together for the Hackathon.

## Connecting to your team's instance

You can reach your instance by visiting the URL given to you. It should be like: `https://ufs-metplus.noaa.gov/<teamname>/#<username>` where teamname and username are replaced with the actual values.

## Orientation

You can find the METplus git repo installed in your users home directory, alongside METcalcpy, METplotpy, and METdatadb. A Python conda environment has been set up and activated for you that will work with METplus. If you need other Python packages, you should be able to install them with conda.

METplus has been configured to output to `~/metplus-output`

You can find data for the hackathon in `/metplus-data`. The following datasets are available to you:

* `/metplus-data/hackathon/olr`
    * https://psl.noaa.gov/data/gridded/data.interp_OLR.html
* `/metplus-data/hackathon/usf-s2s`
    * https://registry.opendata.aws/noaa-ufs-s2s/ 
* `/metplus-data/hackathon/era5`
    * https://registry.opendata.aws/ecmwf-era5/
* `/metplus-data/hackathon/gefs`
    * https://registry.opendata.aws/noaa-gefs-reforecast/
* `/metplus-data/model_applications/s2s` # TODO - figure out permissions
    * https://dtcenter.ucar.edu/dfiles/code/METplus/METplus_Data/v4.1/sample_data-s2s-4.1.tgz

We also have set up some scratch space for sharing files with your teammate in `/hackathon-scratch`

The instance you're working on has 500 GB of disk space, so please be cognizant of your disk usage. `df -h` is a great command to view your remaining disk space. If you start to run out of space, clean up any unneeded output files, and if you still are running low on disk space please let the Hackathon organizers know.

### Available tools

* Python & Package Management
    * [conda](https://docs.conda.io/projects/conda/en/latest/user-guide/index.html)
* Editors
    * [VSCode](https://code.visualstudio.com/)
        * We recommend configuring the Python plugin to use the Conda environment we've set up. To do so, select and activate the environment labeled `Python 3.8.10 ('metplus-hackathon')` by following the instructions here: https://code.visualstudio.com/docs/python/environments#_select-and-activate-an-environment
    * [vim](https://wiki.gentoo.org/wiki/Vim/Guide)
    * [nano](https://www.nano-editor.org/dist/latest/nano.html)
    * [emacs](https://www.gnu.org/software/emacs/manual/html_node/emacs/index.html)
* Source control
    * git

### Setting up Git on your instance

The contribution guidelines for METplus can be found here: https://metplus.readthedocs.io/en/latest/Contributors_Guide/github_workflow.html. You will need to fork the METplus repo for your team. Once that is done, you can configure METplus in the instance to work with your fork with the following:

```
git remote set-url origin git@github.com:<your fork location>/METplus.git
git switch develop
git pull
git switch -c metplus-ufs-hackathon-$TEAMNAME # Where $TEAMNAME is the name of your team
```

You can then make changes to METplus and share your code with your teammate via git. We recommend committing early and often. If you have other questions on how to use git you can consult the excellent git book available online for free here: https://git-scm.com/book/en/v2

## Working with METplus

The main entrypoint to METplus is the `run_metplus.py` command. Otherwise, guidance on how to use METplus can be found at the following locations:

* Documentation: https://metplus.readthedocs.io/en/main_v4.0/Users_Guide/ 
* Training Series: 
    * https://dtcenter.org/events/2021/metplus-training-series
    * https://metplus-training.readthedocs.io/en/latest/modules/Tutorial/index.html
* METplus help forum: https://github.com/dtcenter/METplus/discussions

## Useful Links

* https://vlab.noaa.gov/web/ufs-r2o/2022-metplus-hackathon
