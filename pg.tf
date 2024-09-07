# Create a PostgreSQL database cluster
resource "digitalocean_database_cluster" "pg_instance" {
  name                 = "pgdbwebdo"                 # Name of the PostgreSQL cluster
  engine               = "pg"                        # PostgreSQL engine
  version              = "16"                        # PostgreSQL version
  region               = "fra1"                      # Region (e.g., Frankfurt)
  size                 = "db-s-1vcpu-1gb"            # Database instance size
  node_count           = 1                           # Number of nodes in the cluster
  private_network_uuid = digitalocean_vpc.vpc-0-0.id # Attach to the created VPC
}

# Create a new database in the cluster
resource "digitalocean_database_db" "db_instance" {
  cluster_id = digitalocean_database_cluster.pg_instance.id # Attach to the cluster
  name       = "dbwebdo"                                    # Custom database name
}

# null_resource for updating DNS records (using the Hetzner API)
resource "null_resource" "update_dns" {
  triggers = {
    endpoint = digitalocean_database_cluster.pg_instance.host
  }

  provisioner "file" {
    source      = "restore_pg_dump.sh"
    destination = "/tmp/restore_pg_dump.sh"
    connection {
      type        = "ssh"
      host        = digitalocean_droplet.vm_0_0.ipv4_address
      user        = "root"
      private_key = file("${path.module}/az_ssh_key.pem")
    }
  }

  provisioner "local-exec" {
    command = <<EOT
      # Update DNS using Hetzner API
      python3 update_hetzner.py > /tmp/update_hetzner.log 2>&1; cat /tmp/update_hetzner.log
    EOT
    environment = {
      HETZNER_DNS_KEY     = var.hetzner_dns_key
      HETZNER_C_NAME      = digitalocean_database_cluster.pg_instance.host
      HETZNER_RECORD_NAME = "pgdo"
      HETZNER_DOMAIN_NAME = "pam4.com"
    }
  }
}

# Create a firewall for the PostgreSQL database after Droplet creation
resource "digitalocean_database_firewall" "pg_sg_update" {
  cluster_id = digitalocean_database_cluster.pg_instance.id

  # Allow access only from Droplet
  rule {
    type  = "droplet"
    value = digitalocean_droplet.vm_0_0.id # Allow access from the Droplet
  }

  depends_on = [digitalocean_droplet.vm_0_0] # Ensure Droplet is created before updating firewall
}

# Output the PostgreSQL database username
output "db_user" {
  description = "The username for the PostgreSQL database"
  value       = digitalocean_database_cluster.pg_instance.user
}

# Output the PostgreSQL database password (sensitive)
output "db_password" {
  description = "The password for the PostgreSQL database"
  value       = digitalocean_database_cluster.pg_instance.password
  sensitive   = true
}
