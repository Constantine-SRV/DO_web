terraform {
  backend "s3" {
    endpoints = {
      s3 = "https://fra1.digitaloceanspaces.com"  
    }
    bucket     = "tf2-state-store"
    key        = "terraform.tfstate"
    region     = "fra1"
    skip_region_validation = true
    skip_credentials_validation = true
  }

  required_version = ">= 1.4"
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.21.0"
    }
  }
}

provider "digitalocean" {
  token = var.do_token
}
