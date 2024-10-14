## Project Variables
variable "projectName" {
  description = "Project Name"
  type        = string
  default     = "cwa"
}

variable "environment" {
  description = "Environment Name"
  type        = string
  default     = "dev"
}

## VPC Variables
variable "vpcCIDR" {
  description = "CIDR Block for VPC"
  type = string
}

## Subnet Variables
variable "subnetsAZList" {
  description = "List of Public Subnet AZ"
  type = list(string)
}

variable "publicSubnetsCIDRList" {
  description = "List of Public Subnet CIDR Blocks"
  type = list(string)
}

variable "privateNatSubnetsCIDRList" {
  description = "List of Private Nat Subnet CIDR Blocks"
  type = list(string)
}

variable "privateSubnetsCIDRList" {
  description = "List of Private Subnet CIDR Blocks"
  type = list(string)
}