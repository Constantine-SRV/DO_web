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

# Create a firewall for the PostgreSQL database
resource "digitalocean_database_firewall" "pg_sg" {
  cluster_id = digitalocean_database_cluster.pg_instance.id # Associate with the PostgreSQL cluster

  # Allow access from a specific Droplet
  rule {
    type  = "droplet"
    value = digitalocean_droplet.vm_0_0.id # Allow access from the Droplet
  }

  # Uncomment to allow access from all IPs (public access), removing all trusted sources
  # trusted_sources = []
}

# null_resource for updating DNS records (using the Hetzner API) and restoring database from a dump
resource "null_resource" "update_dns_and_restore_db" {
  triggers = {
    endpoint = digitalocean_database_cluster.pg_instance.host
  }

  provisioner "local-exec" {
    command = <<EOT
      # Update DNS using Hetzner API
      python3 update_hetzner.py > /tmp/update_hetzner.log 2>&1; cat /tmp/update_hetzner.log

      # Restore database from a dump
      export DB_HOST='${digitalocean_database_cluster.pg_instance.host}'
      export DB_USER='${digitalocean_database_cluster.pg_instance.user}' # Take user from the cluster
      export DB_PASS='${digitalocean_database_cluster.pg_instance.password}'
      export DB_NAME='${digitalocean_database_db.db_instance.name}' # Take DB name from the created database
      export DB_PORT='${digitalocean_database_cluster.pg_instance.port}' # Pass the correct port
      export ACC_KEY='${var.arm_access_key}'
      sudo mv /tmp/restore_pg_dump.sh /usr/local/bin/restore_pg_dump.sh
      sudo chmod +x /usr/local/bin/restore_pg_dump.sh
      sudo -E /usr/local/bin/restore_pg_dump.sh
    EOT
    environment = {
      HETZNER_DNS_KEY     = var.hetzner_dns_key
      HETZNER_C_NAME      = digitalocean_database_cluster.pg_instance.host
      HETZNER_RECORD_NAME = "pgdo"
      HETZNER_DOMAIN_NAME = "pam4.com"
    }
  }

  provisioner "file" {
    source      = "restore_pg_dump.sh"
    destination = "/tmp/restore_pg_dump.sh"
  }
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
