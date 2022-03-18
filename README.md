# VxMETplusAMI
Hashicorp Packer files for creating a METplus AMI for the METplus 2022 Hackathon

## Getting started

```console
# Define the required variables in a file
$ cat << EOF > vars.auto.pkrvars.hcl
subnet_id = "subnet-id"

security_group_ids = [
  "sg-id1", # inbound SSH access from where Packer is being run
  "sg-id2", # outbound access to the internet
]

tags = {
  "tag1" = "value1"
  "tag2"  = "value2"
}
EOF
$ packer init .
$ packer validate .
$ packer fmt .
$ packer build metplus.pkr.hcl
```

The build will take roughly an hour to download and configure everything.

## Development

### Docs

[Packer EBS builder](https://www.packer.io/plugins/builders/amazon/ebs)

### Variable Files

[Documentation](https://learn.hashicorp.com/tutorials/packer/aws-get-started-variables?in=packer/aws-get-started)

A variable file named like so `vars.auto.pkrvars.hcl` will be auto loaded by Packer.

Pass `-var-file=` to use a different variable file to e.g. - target different accounts.

## METplus Installation Notes

This installation assumes:
- MET is installed in `/opt/met` with system python embedding
- 2 non-admin users in the AMI (TODO)
    - The rest of the METplus suite installed in $HOME
    - Miniconda set up for each user
    - [METplus's py_embed_base env](https://github.com/dtcenter/METplus/blob/main_v4.1/scripts/docker/docker_env/scripts/py_embed_base_env.sh) enabled by default
    - `MET_PYTHON_EXE` set to miniconda python
    - vim, nano, emacs are installed and X11 forwarding is enabled
- S2S sample data installed in `/metplus-data` from: https://dtcenter.ucar.edu/dfiles/code/METplus/METplus_Data/v4.1/sample_data-s2s-4.1.tgz
    - more sample data can be found here: https://dtcenter.ucar.edu/dfiles/code/METplus/METplus_Data/v4.1/
- The OLR and various BDP datasets mounted in `/metplus-data/hackathon`
