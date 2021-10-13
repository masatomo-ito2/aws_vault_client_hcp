provider "hcp" {}

# HCP HVN
data "hcp_hvn" "hcp_vault_hvn" {
  hvn_id = var.hvn_id
}

# HCP Vault cluster
data "hcp_vault_cluster" "vault_cluster" {
  cluster_id = var.vault_cluster_id
}

# Peering
data "aws_arn" "peer" {
  arn = local.vpc_arn
}

resource "hcp_aws_network_peering" "peer" {
  hvn_id          = data.hcp_hvn.hcp_vault_hvn.hvn_id
  peering_id      = var.hvn_peering_id
  peer_vpc_id     = local.vpc_id
  peer_account_id = local.vpc_owner_id
  peer_vpc_region = data.aws_arn.peer.region
}

resource "hcp_hvn_route" "peering-route" {
  hvn_link         = data.hcp_hvn.hcp_vault_hvn.self_link
  hvn_route_id     = var.hvn_route_id
  destination_cidr = local.vpc_cidr_block
  target_link      = hcp_aws_network_peering.peer.self_link
}

resource "aws_vpc_peering_connection_accepter" "peer" {
  vpc_peering_connection_id = hcp_aws_network_peering.peer.provider_peering_id
  auto_accept               = true
}

# route table
resource "aws_route" "hvn_peering" {
  route_table_id            = local.vpc_main_route_table_id
  destination_cidr_block    = data.hcp_hvn.hcp_vault_hvn.cidr_block
  vpc_peering_connection_id = hcp_aws_network_peering.peer.provider_peering_id
}

/*
resource "aws_route_table" "hvn_peering" {
  vpc_id = local.vpc_id

  route {
    cidr_block                = data.hcp_hvn.hcp_vault_hvn.cidr_block
    vpc_peering_connection_id = hcp_aws_network_peering.peer.provider_peering_id
  }

  tags = {
    Name = "${var.prefix}-HVN-peering"
  }
}
*/
