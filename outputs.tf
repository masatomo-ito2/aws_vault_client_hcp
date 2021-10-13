# AWS Instance
output "public_ip" {
  value = aws_instance.vault_client.public_ip
}

output "public_dns" {
  value = aws_instance.vault_client.public_dns
}

# HCP

locals {
  v = data.hcp_vault_cluster.vault_cluster
}

output "vault_public_url" {
  value = local.v.vault_public_endpoint_url
}

output "vault_private_url" {
  value = local.v.vault_private_endpoint_url
}

output "vault_info" {

  value = <<EOF
cloud_provider = ${local.v.cloud_provider}
created_at = ${local.v.created_at}
hvn_id = ${local.v.hvn_id}
organization_id = ${local.v.organization_id}
project_id = ${local.v.project_id}
vault_version = ${local.v.vault_version}
namespace = ${local.v.namespace}
region = ${local.v.region}
tier = ${local.v.tier}
public_endpoint = ${local.v.public_endpoint}
EOF
}
