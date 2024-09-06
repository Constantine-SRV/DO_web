terraform {
  required_version = ">= 1.6.3"

  backend "s3" {
    endpoints = {
      s3 = "https://fra1.digitaloceanspaces.com"  # Регион вашего Space
    }
    bucket = "tf2-state-store"                   # Имя вашего Space
    key    = "terraform.tfstate"                 # Имя файла состояния
    region = "us-east-1"                         # Необязательно, стандартная для S3 совместимости

    # Отключаем AWS-специфические проверки, так как используем DigitalOcean Spaces
    skip_credentials_validation = true
    skip_requesting_account_id  = true
    skip_metadata_api_check     = true
    skip_region_validation      = true
    skip_s3_checksum            = true
  }
}

provider "digitalocean" {
  token = var.do_token  # Используем API токен DigitalOcean
}
