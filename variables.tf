variable "ENV" {
  type = string
  default = "dev"
  validation {
    condition     = contains(["dev", "prod"], var.ENV)
    error_message = "Valid values for var: ENV are (dev, prod)."
  } 
}

variable "AWS_REGION" {
  default = "ap-southeast-2"
}

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

variable "PRIVATE_CLUSTER" {
  type = bool
  default = false
}

variable "ROSA_TOKEN" {
  type = string
  sensitive = true
}