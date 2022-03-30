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
    device_name           = "/dev/sda1" # reserved root name
    volume_size           = 40
    volume_type           = "gp2"
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
  provisioner "file" {
    source      = "METconfig/install_met_env.centos_aws"
    destination = "/tmp/install_met_env.centos_aws"
  }
  provisioner "shell" {
    execute_command = "sudo bash -c '{{ .Vars }} {{ .Path }}'"
    scripts = [
      "scripts/install_met.sh"
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
      "sudo yum -y install fuse fuse-libs", # Make fuse available for goofys
      "sudo wget -P /usr/local/bin https://github.com/kahing/goofys/releases/download/v0.24.0/goofys && sudo chmod +x /usr/local/bin/goofys",
      "echo \"Done Installing editors & goofys\"",
    ]
  }
  provisioner "shell" {
    inline_shebang = "/bin/bash -e"
    inline = [
      "echo \"Setting up data\"",
      "sudo mkdir -p /metplus-data/met_test",
      "sudo mkdir -p /metplus-data/hackathon/olr /metplus-data/hackathon/ufs-s2s /metplus-data/hackathon/era5 /metplus-data/hackathon/gefs",
      # OLR dataset
      "sudo wget -P /metplus-data/hackathon/olr https://downloads.psl.noaa.gov/Datasets/interp_OLR/olr.day.mean.nc",
      # METplus S2S use case sample data
      "wget -qO - https://dtcenter.ucar.edu/dfiles/code/METplus/METplus_Data/v4.1/sample_data-s2s-4.1.tgz | sudo tar -xz -C /metplus-data",
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
  provisioner "shell" {
    inline_shebang = "/bin/bash -e"
    inline = [
      "echo \"Creating users\"",
      "sudo adduser user1",
      "sudo adduser user2",
      "sudo groupadd hackathon",
      "sudo usermod -aG hackathon user1",
      "sudo usermod -aG hackathon user2",
      # Remove the user's password - otherwise CentOS requires one to be set
      "sudo passwd -d user1",
      "sudo passwd -d user2",
      # Create a location for both users to share files
      "sudo mkdir -p /hackathon-scratch",
      "sudo setfacl --recursive --modify group:hackathon:rwX,default:group:hackathon:rwX /hackathon-scratch",
      "echo \"Done Creating users\""
    ]
  }
  provisioner "file" {
    source      = "METconfig/Externals.cfg"
    destination = "/tmp/"
  }
  provisioner "file" {
    sources = [
      "scripts/install_metplus.sh",
      "scripts/install_miniconda.sh"
    ]
    destination = "/tmp/"
  }
  provisioner "shell" {
    inline_shebang = "/bin/bash -e"
    inline = [
      "echo \"Installing METplus\"",
      "sudo -i -u user1 bash -c \"bash /tmp/install_metplus.sh; bash /tmp/install_miniconda.sh\"",
      "sudo -i -u user2 bash -c \"bash /tmp/install_metplus.sh; bash /tmp/install_miniconda.sh\"",
      "echo \"Done Installing METplus\""
    ]
  }
  provisioner "file" {
    source      = "METconfig/environment.yml"
    destination = "/tmp/environment.yml"
  }
  # Restart shell for conda init to take affect & install metplus dependencies
  provisioner "shell" {
    inline_shebang = "/bin/bash -e"
    inline = [
      "echo \"Installing metplus dependencies\"",
      # Set up conda metplus environment
      "cp /tmp/environment.yml $HOME/METplus/environment.yml",
      "conda env create -f $HOME/METplus/environment.yml",
      # Tell MET to use miniconda Python
      "echo \"export MET_PYTHON_EXE=$(which python)\" >> $HOME/.bashrc",
      # Put MET & METplus on PATH
      "echo \"export PATH=/opt/met/bin:$HOME/METplus/ush:$PATH\" >> $HOME/.bashrc",
      # Activate conda env in user's .bashrc
      "echo \"conda activate metplus-hackathon\" >> $HOME/.bashrc",
      "echo \"Done installing metplus dependencies\""
    ]
  }
}
