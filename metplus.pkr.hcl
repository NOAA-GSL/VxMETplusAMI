packer {
  required_plugins {
    amazon = {
      version = ">= 0.0.2"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

data "amazon-ami" "amazon-linux-2-east" {
  # ssh_username = ec2-user
  region = "us-east-1"
  filters = {
    name                = "amzn2-ami-kernel-*-hvm*"
    root-device-type    = "ebs"
    virtualization-type = "hvm"
    architecture        = "x86_64"
  }
  most_recent = true
  owners      = ["137112412989"]
}

data "amazon-ami" "centos7-east" {
  # ssh_username = centos
  region = "us-east-1"
  filters = {
    name                = "CentOS 7*"
    root-device-type    = "ebs"
    virtualization-type = "hvm"
    architecture        = "x86_64" # Note - CentOS 7 doesn't support ARM
  }
  most_recent = true
  owners      = ["125523088429"] # Official CentOS Account
  # owners      = ["679593333241"] # AWS Marketplace maybe?
}

source "amazon-ebs" "centos7-latest" {
  ami_name      = "metplus-centos7-aws-{{ timestamp }}"
  instance_type = "t2.micro"
  ssh_username  = "centos"
  region        = "us-east-1"
  source_ami    = data.amazon-ami.centos7-east.id
  subnet_id     = "subnet-010d4fe54e66b6ed2" # Subnet 1b public
  security_group_ids = [
    "sg-0392385c9daedc571", # gsl_inbound_ssh.id,
    "sg-0eb84211ccf1f7c07", # aws_inbound_ssh.id,
    "sg-0c8b5daa04f90d381", # aws_outbound_anywhere.id
  ]
  run_volume_tags = {
    "noaa:oar:gsl:vx:project" = "metplus-hackathon-2022"
    "noaa:oar:gsl:projectid"  = "2021-1-AVID-metexpress"
    "Project"                 = "AVID"
  }
  run_tags = { # Tags for the instance used to create AMI
    "noaa:oar:gsl:vx:project" = "metplus-hackathon-2022"
    "noaa:oar:gsl:projectid"  = "2021-1-AVID-metexpress"
    "Project"                 = "AVID"
    "Base_AMI_ID"             = "{{ .SourceAMI }}"
    "Base_AMI_Name"           = "{{ .SourceAMIName }}"
  }
  tags = { # Tags for the AMI
    "noaa:oar:gsl:vx:project" = "metplus-hackathon-2022"
    "noaa:oar:gsl:projectid"  = "2021-1-AVID-metexpress"
    "Project"                 = "AVID"
    "Base_AMI_ID"             = "{{ .SourceAMI }}"
    "Base_AMI_Name"           = "{{ .SourceAMIName }}"
    "Name"                    = "METPlus Hackathon"
  }
}

# NOTE - if this gets lengthy it may make sense to split this into a sources.pkr.hcl
# and a build.pkr.hcl file. We could use multiple sources (E.g. - CentOS in GCP & AWS)
# for this one builder.

build {
  name = "metplus-centos7"
  sources = [
    "source.amazon-ebs.centos7-latest"
  ]
  # Inline install commands inspired by the MET Dockerfile here: https://github.com/dtcenter/MET/blob/main_v10.0/scripts/docker/Dockerfile
  provisioner "shell" {
    inline = [
      "echo Installing required packages",
      "sudo yum -y update",
      "sudo yum -y install file gcc gcc-gfortran gcc-c++ glibc.i686 libgcc.i686 libpng-devel jasper jasper-devel zlib zlib-devel cairo-devel freetype-devel epel-release hostname m4 make tar tcsh ksh time wget which flex flex-devel bison bison-devel unzip",
      "sudo yum -y install git g2clib-devel hdf5-devel.x86_64 gsl-devel",
      "sudo yum -y install gv ncview wgrib wgrib2 ImageMagick ps2pdf",
      "sudo yum -y install python3 python3-devel python3-pip",
      "sudo pip3 install --upgrade pip",
      "sudo python3 -m pip install numpy xarray netCDF4",
      "echo Done Installing packages"
    ]
  }
  provisioner "file" {
    source      = "install_met_env.centos_aws"
    destination = "/tmp/install_met_env.centos_aws"
  }
  provisioner "shell" {
    # inline_shebang = "/bin/bash -e"
    inline = [
      "echo Install MET",
      "sudo mkdir -p /met/tar_files && cd /met",
      "sudo mv /tmp/install_met_env.centos_aws /met/ && sudo chmod +x /met/install_met_env.centos_aws",
      "sudo wget https://raw.githubusercontent.com/dtcenter/MET/develop/scripts/installation/compile_MET_all.sh",
      "sudo chmod 775 compile_MET_all.sh",
      "sudo wget https://dtcenter.ucar.edu/dfiles/code/METplus/MET/installation/tar_files.tgz",
      "sudo tar -zxf tar_files.tgz && sudo rm tar_files.tgz",
      "sudo wget -P /met/tar_files https://github.com/dtcenter/MET/releases/download/v10.0.1/met-10.0.1.20211201.tar.gz",
      "sudo bash compile_MET_all.sh install_met_env.centos_aws",
      "echo Done Installing MET"
    ]
  }
}
