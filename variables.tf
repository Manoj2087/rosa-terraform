variable "CLUSTER_PREFIX" {
  default = "rosa"
}

variable "VPC_CIDR" {
  default = "10.0.0.0/16"
}

variable "MULTI_AZ" {
  type = bool
  default = false
}