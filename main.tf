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

locals {
  vpc_id    = data.terraform_remote_state.this.outputs.vpc_id_japan
  subnet_id = data.terraform_remote_state.this.outputs.public_subnets_japan[0]
}

resource "aws_security_group" "vault_client" {
  name = "${var.prefix}-security-group"

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
    Name = "${var.prefix}-security-group"
  }
}

resource "aws_internet_gateway" "vault_client" {
  vpc_id = local.vpc_id

  tags = {
    Name = "${var.prefix}-internet-gateway"
  }
}

resource "aws_route_table" "vault_client" {
  vpc_id = local.vpc_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.vault_client.id
  }
}

resource "aws_route_table_association" "vault_client" {
  subnet_id      = local.subnet_id
  route_table_id = aws_route_table.vault_client.id
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name = "name"
    #values = ["ubuntu/images/hvm-ssd/ubuntu-disco-19.04-amd64-server-*"]
    values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_eip" "vault_client" {
  instance = aws_instance.vault_client.id
  vpc      = true
}

resource "aws_eip_association" "vault_client" {
  instance_id   = aws_instance.vault_client.id
  allocation_id = aws_eip.vault_client.id
}

resource "aws_instance" "vault_client" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  key_name                    = var.key_name
  associate_public_ip_address = true
  subnet_id                   = local.subnet_id
  vpc_security_group_ids      = [aws_security_group.vault_client.id]

  tags = {
    Name = "${var.prefix}-vault_client-instance"
  }
}
