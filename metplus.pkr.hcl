packer {
  required_plugins {
    amazon = {
      version = ">= 0.0.2"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

variable "subnet_id" {
  type = string
}

variable "security_group_ids" {
  type = list(string)
  # The instance needs inbound SSH access from your system and outbound access to the internet
}

variable "tags" {
  type    = map(string)
  default = {}
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
  owners      = ["137112412989"] # AWS account
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
  ami_name           = "metplus-centos7-aws-{{ timestamp }}"
  instance_type      = "t3.xlarge"
  ssh_username       = "centos"
  region             = "us-east-1"
  source_ami         = data.amazon-ami.centos7-east.id
  subnet_id          = var.subnet_id
  security_group_ids = var.security_group_ids
  launch_block_device_mappings {
      device_name = "/dev/sda1" # reserved root name
      volume_size = 40
      volume_type = "gp2"
      delete_on_termination = true
  }
  run_volume_tags = merge({
    "Base_AMI_ID"   = "{{ .SourceAMI }}"
    "Base_AMI_Name" = "{{ .SourceAMIName }}"
  }, var.tags)
  run_tags = merge({ # Tags for the instance used to create AMI
    "Base_AMI_ID"   = "{{ .SourceAMI }}"
    "Base_AMI_Name" = "{{ .SourceAMIName }}"
  }, var.tags)
  tags = merge({ # Tags for the AMI
    "Base_AMI_ID"   = "{{ .SourceAMI }}"
    "Base_AMI_Name" = "{{ .SourceAMIName }}"
    "Name"          = "METPlus Hackathon"
  }, var.tags)
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
      "echo \"Installing editors & goofys\"",
      "sudo yum -y install epel-release",
      "sudo yum -y install vim nano emacs",
      "sudo yum -y install xorg-x11-xauth", # enable X11 forwarding
      # "sudo yum -y install s3fs-fuse",  # s3fs-fuse gave weird directory traversal errors - use goofys instead
      "sudo yum -y install fuse fuse-libs", # Make fuse available for goofys
      "sudo wget -P /usr/local/bin https://github.com/kahing/goofys/releases/download/v0.24.0/goofys && sudo chmod +x /usr/local/bin/goofys",
      "echo \"Done Installing editors & goofys\"",
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
      # Set up conda py_embed_base environment
      "bash $HOME/METplus/scripts/docker/docker_env/scripts/py_embed_base_env.sh",
      # Activate conda env in user's .bashrc
      "echo \"conda activate py_embed_base\" >> $HOME/.bashrc",
      # Tell MET to use miniconda Python
      "echo \"export MET_PYTHON_EXE=$(which python)\" >> $HOME/.bashrc",
      # Put MET & METplus on PATH
      "echo \"export PATH=/opt/met/bin:$HOME/METplus/ush:$PATH\" >> $HOME/.bashrc",
      "echo \"Done installing miniconda\""
    ]
  }
  provisioner "shell" {
    inline_shebang = "/bin/bash -e"
    inline = [
      "echo \"Setting up data\"",
      "sudo mkdir -p /metplus-data/model_applications/s2s",
      "sudo mkdir -p /metplus-data/met_test",
      "sudo mkdir -p /metplus-data/hackathon/olr /metplus-data/hackathon/ufs-s2s /metplus-data/hackathon/era5 /metplus-data/hackathon/gefs",
      # OLR dataset
      "sudo wget -P /metplus-data/hackathon/olr https://downloads.psl.noaa.gov/Datasets/interp_OLR/olr.day.mean.nc",
      # METplus S2S use case sample data
      "wget -qO - https://dtcenter.ucar.edu/dfiles/code/METplus/METplus_Data/v4.1/sample_data-s2s-4.1.tgz | sudo tar -xzv - -C /metplus-data/model_applications/s2s",
      # Add BDP datasets 
      # For explanation of options, see: https://github.com/kahing/goofys 
      # UFS data: https://registry.opendata.aws/noaa-ufs-s2s/
      "echo \"goofys#noaa-ufs-prototypes-pds /metplus-data/hackathon/ufs-s2s fuse _netdev,allow_other,--file-mode=0444,--dir-mode=0555 0 0\" | sudo tee -a /etc/fstab",
      # ERA 5 data: https://registry.opendata.aws/ecmwf-era5/
      "echo \"goofys#era5-pds /metplus-data/hackathon/era5 fuse _netdev,allow_other,--file-mode=0444,--dir-mode=0555 0 0\" | sudo tee -a /etc/fstab",
      # GEFS re-forecast data: https://registry.opendata.aws/noaa-gefs-reforecast/#usageexamples 
      "echo \"goofys#noaa-gefs-retrospective /metplus-data/hackathon/gefs fuse _netdev,allow_other,--file-mode=0444,--dir-mode=0555 0 0\" | sudo tee -a /etc/fstab",
      "echo \"Done Setting up data\""
    ]
  }
}
