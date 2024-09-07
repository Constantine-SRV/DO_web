# Create a PostgreSQL database cluster
resource "digitalocean_database_cluster" "pg_instance" {
  name                 = "pgdbwebdo"                 # Name of the PostgreSQL cluster
  engine               = "pg"                        # PostgreSQL engine
  version              = "16"                        # PostgreSQL version
  region               = "fra1"                      # Region (e.g., Frankfurt)
  size                 = "db-s-1vcpu-1gb"            # Database instance size
  node_count           = 1                           # Number of nodes in the cluster
  private_network_uuid = digitalocean_vpc.vpc-0-0.id # Attach to the created VPC

  # Database access configuration
  user     = "dbuser"
  password = var.db_password # Use the password from the GitHub secret
}

# Create a new database in the cluster
resource "digitalocean_database_db" "db_instance" {
  cluster_id = digitalocean_database_cluster.pg_instance.id # Attach to the cluster
  name       = "dbwebdo"                                    # Custom database name
}

# Create a firewall for the PostgreSQL database
resource "digitalocean_database_firewall" "pg_sg" {
  cluster_id = digitalocean_database_cluster.pg_instance.id # Associate with the PostgreSQL cluster

  # Allow access from a specific IP address (public access)
  rule {
    type  = "ip_addr"
    value = "0.0.0.0/0" # Allow public access to the database
  }

  # Allow access from a specific Droplet
  rule {
    type  = "droplet"
    value = digitalocean_droplet.vm_0_0.id # Allow access from the Droplet
  }
}

# null_resource for updating DNS records (using the Hetzner API)
resource "null_resource" "update_dns" {
  triggers = {
    endpoint = digitalocean_database_cluster.pg_instance.host
  }

  provisioner "local-exec" {
    command = "python3 update_hetzner.py"
    environment = {
      HETZNER_DNS_KEY     = var.hetzner_dns_key
      HETZNER_C_NAME      = digitalocean_database_cluster.pg_instance.host
      HETZNER_RECORD_NAME = "pgdo"
      HETZNER_DOMAIN_NAME = "pam4.com"
    }
  }
}

