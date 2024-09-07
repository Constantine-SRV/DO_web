provider "digitalocean" {
  token = var.do_token  # Use DigitalOcean API token
}

# Создаем VPC с диапазоном IP адресов
resource "digitalocean_vpc" "vpc_0_0" {
  name   = "0_0_VPC"
  region = "fra1"  # Region for VPC (e.g., Frankfurt)
  ip_range = "10.10.0.0/16"  # CIDR block for VPC
  
  description = "VPC for Terraform Droplet"
}

# Создаем Droplet в указанной VPC
resource "digitalocean_droplet" "vm_0_0" {
  name   = "terraform-droplet"
  region = "fra1"  # Region for Droplet (e.g., Frankfurt)
  size   = "s-1vcpu-1gb"  # Droplet size
  image  = "ubuntu-22-04-x64"  # OS image for the Droplet
  vpc_uuid = digitalocean_vpc.vpc_0_0.id  # Attach Droplet to created VPC

  # Use the existing SSH key
  ssh_keys = [data.digitalocean_ssh_key.az_ssh_key.id]

  tags = ["terraform", "droplet"]
}

# Fetch the existing SSH key
data "digitalocean_ssh_key" "az_ssh_key" {
  name = "az_ssh_key_pem"  # Name of your existing SSH key
}

# Output to get the public IP of the Droplet
output "droplet_ip" {
  description = "The public IP address of the Droplet"
  value       = digitalocean_droplet.vm_0_0.ipv4_address
}
