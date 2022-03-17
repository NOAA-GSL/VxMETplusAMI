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
}

source "amazon-ebs" "centos7-latest" {
  ami_name      = "metplus-centos7-aws-{{ timestamp }}"
  instance_type = "t3.small"
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
  # Install inspired by the MET Dockerfile here: https://github.com/dtcenter/MET/blob/main_v10.0/scripts/docker/Dockerfile
  provisioner "shell" {
    inline_shebang = "/bin/bash -e"
    inline = [
      "echo \"Installing required packages\"",
      "sudo yum -y update",
      "sudo yum -y install file gcc gcc-gfortran gcc-c++ glibc.i686 libgcc.i686 libpng-devel jasper jasper-devel zlib zlib-devel cairo-devel freetype-devel epel-release hostname m4 make tar tcsh ksh time which wget flex flex-devel bison bison-devel unzip",
      "sudo yum -y install git g2clib-devel hdf5-devel.x86_64 gsl-devel",
      "sudo yum -y install gv ncview wgrib wgrib2 ImageMagick ps2pdf",
      "sudo yum -y install python3 python3-devel python3-pip",
      "sudo pip3 install --upgrade pip",
      "sudo python3 -m pip install numpy xarray netCDF4", #dateutil? 
      # NOTE - user will need to set MET_PYTHON_EXE if they use conda (conda activate <env> && which python)
      "echo \"Done Installing packages\""
    ]
  }
  provisioner "file" {
    source      = "METconfig/install_met_env.centos_aws"
    destination = "/tmp/install_met_env.centos_aws"
  }
  provisioner "shell" {
    inline_shebang = "/bin/bash -e"
    inline = [
      "echo \"Install MET\"",
      "sudo mkdir -p /opt/met/tar_files && cd /opt/met",
      "sudo mv /tmp/install_met_env.centos_aws /opt/met/ && sudo chmod +x /opt/met/install_met_env.centos_aws",
      "sudo wget https://raw.githubusercontent.com/dtcenter/MET/main_v10.1/scripts/installation/compile_MET_all.sh",
      "sudo chmod 775 compile_MET_all.sh",
      "sudo wget https://dtcenter.ucar.edu/dfiles/code/METplus/MET/installation/tar_files.tgz",
      "sudo tar -zxf tar_files.tgz && sudo rm tar_files.tgz",
      "sudo wget -P /opt/met/tar_files https://github.com/dtcenter/MET/releases/download/v10.1.0/met-10.1.0.20220314.tar.gz",
      "sudo bash compile_MET_all.sh install_met_env.centos_aws",
      "echo \"Done Installing MET\""
    ]
  }
  # User Setup
  provisioner "shell" {
    inline_shebang = "/bin/bash -e"
    inline = [
      "echo \"Installing editors & s3fs-fuse\"",
      "sudo yum -y install epel-release",
      "sudo yum -y install vim nano emacs",
      "sudo yum -y install xorg-x11-xauth", # enable X11 forwarding
    ]
  }
  # TODO - create other users and do the below as them
  provisioner "file" {
    sources     = ["METconfig/Externals.cfg", "METconfig/defaults.conf"]
    destination = "/tmp/"
  }
  provisioner "shell" {
    inline_shebang = "/bin/bash -e"
    inline = [
      "echo \"Install METplus\"",
      "echo $(pwd) && cd $HOME", # TODO - delete
      "git clone https://github.com/dtcenter/METplus",
      # Copy our patched Externals.cfg into place
      "cp /tmp/Externals.cfg $HOME/METplus/build_components/Externals.cfg",
      # METplus looks for the defaults.conf file using a relative path
      "cp /tmp/defaults.conf $HOME/METplus/parm/metplus_config/defaults.conf",
      # TODO - switch to develop branch? https://metplus.readthedocs.io/en/latest/Contributors_Guide/github_workflow.html
      "cd METplus && manage_externals/checkout_externals -e build_components/Externals.cfg",
      "mkdir $HOME/metplus-output",
      "echo \"Done Installing METplus\""
    ]
  }
  # Install Miniconda & metplus dependencies
  provisioner "shell" {
    inline_shebang = "/bin/bash -e"
    inline = [
      "echo \"Installing miniconda\"",
      "wget -P /tmp https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh",
      "bash /tmp/Miniconda3-latest-Linux-x86_64.sh -b -p $HOME/miniconda",
      "source $HOME/miniconda/bin/activate && conda init",
      # TODO: Set up conda py_embed_base environments & activate in user's .bashrc
      # "bash ~/metplus/scripts/docker/docker_env/scripts/py_embed_base_env.sh",
      # "conda activate py_embed_base",
      # "conda env list",
      "echo \"Done installing miniconda\""
    ]
  }
  provisioner "shell" {
    inline_shebang = "/bin/bash -e"
    inline = [
      "echo \"Setting up data\"",
      "sudo mkdir -p /metplus-data/model_applications/s2s",
      "sudo mkdir -p /metplus-data/met_test",
      "sudo mkdir -p /metplus-data/hackathon",
      "sudo wget -P /metplus-data/hackathon https://downloads.psl.noaa.gov/Datasets/interp_OLR/olr.day.mean.nc",
      "wget -q0- https://dtcenter.ucar.edu/dfiles/code/METplus/METplus_Data/v4.1/sample_data-s2s-4.1.tgz | sudo tar xzv -C /metplus-data/model_applications/s2s",
      "echo \"Done Setting up data\""
    ]
  }
}
