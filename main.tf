terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "=3.42.0"
    }
  }
}

provider "aws" {
  region = var.region
}

data "terraform_remote_state" "this" {
  backend = "remote"

  config = {
    organization = var.tfc_org
    workspaces = {
      name = var.tfc_ws
    }
  }
}

resource "aws_security_group" "vault_client" {
  name = "${var.prefix}-hcp-security-group"

  vpc_id = local.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
    prefix_list_ids = []
  }

  tags = {
    Name = "${var.prefix}-hcp-security-group"
  }
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_instance" "vault_client" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  key_name                    = var.key_name
  associate_public_ip_address = true
  subnet_id                   = local.subnet_id
  vpc_security_group_ids      = [aws_security_group.vault_client.id]
  user_data                   = data.template_file.vault.rendered

  tags = {
    Name = "${var.prefix}-vault-hcp-client-instance"
  }
}

data "template_file" "vault" {
  template = file("${path.module}/files/deploy_vault.sh.tpl")

  vars = {
    VAULT_VERSION = var.vault_version
    VAULT_ADDR    = local.v.vault_public_endpoint_url
    # VAULT_ADDR = local.v.vault_private_endpoint_url
    VAULT_NAMESPACE          = "admin"
    VAULT_SSH_HELPER_VERSION = var.vault_ssh_helper_version
  }
}
