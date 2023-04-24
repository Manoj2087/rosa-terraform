terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
    # shell = {
    #   source  = "scottwinkler/shell"
    #   version = "1.7.10"
    # }
  }
}

provider "aws" {
  region = "ap-southeast-2"
  ignore_tags {
    key_prefixes = ["kubernetes.io/"]
  }
}

# provider "shell" {
#   interpreter = ["/bin/bash", "-c"]
#   enable_parallelism = false
# }


