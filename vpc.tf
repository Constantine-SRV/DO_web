# Create a VPC with a custom IP range
resource "digitalocean_vpc" "fra1-10-0" {
  name     = "vpc-0-0"      # Updated name to use only valid characters (letters, numbers, hyphens)
  region   = "fra1"         # Region for VPC (e.g., Frankfurt)
  ip_range = "10.10.0.0/16" # CIDR block for VPC

  description = "VPC for Terraform Droplet"
}
