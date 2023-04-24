terraform {
  required_providers {
    shell = {
      source  = "scottwinkler/shell"
      version = "1.7.10"
    }
  }
}

provider "shell" {
  interpreter = ["/bin/bash", "-c"]
  enable_parallelism = false
}
