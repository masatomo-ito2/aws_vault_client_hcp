##############################################################################
# Variables File
##############################################################################

variable "prefix" {
  description = "This prefix will be included in the name of most resources."
}

variable "region" {
  type        = string
  description = "The region where the resources are created."
  default     = "ap-northeast-1"
}

variable "instance_type" {
  type        = string
  description = "Specifies the AWS instance type."
  default     = "t2.micro"
}

variable "vault_version" {
  type    = string
  default = "1.8.4"
}

variable "tfc_org" {
  type = string
}

variable "tfc_ws" {
  type = string
}

variable "key_name" {
	type = string
}
