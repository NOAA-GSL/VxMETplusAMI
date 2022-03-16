# VxMETplusAMI
Hashicorp Packer files for creating a METplus AMI for the METplus 2022 Hackathon

## Getting started

```console
packer init .
packer fmt .
packer validate .
packer build metplus.pkr.hcl
```

## Development

### Docs

https://www.packer.io/plugins/builders/amazon/ebs

### Variable Files

https://learn.hashicorp.com/tutorials/packer/aws-get-started-variables?in=packer/aws-get-started

A variable file named like so `foo.auto.pkrvars.hcl` will be auto loaded by Packer.

Pass `--var-file=` to use a different variable file
