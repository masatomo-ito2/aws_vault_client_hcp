locals {
  vpc_id                  = data.terraform_remote_state.this.outputs.vpc_id_japan
  vpc_arn                 = data.terraform_remote_state.this.outputs.vpc_arn_japan
  subnet_id               = data.terraform_remote_state.this.outputs.public_subnets_japan[0]
  vpc_owner_id            = data.terraform_remote_state.this.outputs.vpc_owner_id_japan
  vpc_cidr_block          = data.terraform_remote_state.this.outputs.vpc_cidr_block_japan
  vpc_main_route_table_id = data.terraform_remote_state.this.outputs.vpc_main_route_table_id_japan
}
