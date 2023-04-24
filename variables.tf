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

variable "OCP_VERSION" {
  default = "4.12.12"
}

variable "WORKER_MACHINE_TYPE" {
  type = map
  default = {
    dev = "t3a.xlarge"
    prod = "m5.xlarge"
  }
}

variable "WORKER_MACHINE_REPLICA" {
  type = map
  default = {
    dev = 2
    prod = 3
  }
}

variable "SERVICE_CIDR" {
  default = "172.30.0.0/16"
}

variable "POD_CIDR" {
  default = "10.128.0.0/14"
}

variable "HOST_PREFIX" {
  default = 23
}