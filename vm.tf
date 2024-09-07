# Create a Droplet in the specified VPC
resource "digitalocean_droplet" "vm_0_0" {
  name     = "terraform-droplet"
  region   = "fra1"                      # Region for Droplet (e.g., Frankfurt)
  size     = "s-1vcpu-1gb"               # Droplet size
  image    = "ubuntu-22-04-x64"          # OS image for the Droplet
  vpc_uuid = digitalocean_vpc.vpc-0-0.id # Attach Droplet to the created VPC

  # Use the existing SSH key
  ssh_keys = [data.digitalocean_ssh_key.az_ssh_key.id]

  tags = ["terraform", "droplet"]

  # Upload setup script to the Droplet
  provisioner "file" {
    source      = "setup_instance.sh"
    destination = "/tmp/setup_instance.sh"
    connection {
      type        = "ssh"
      host        = self.ipv4_address
      user        = "root"
      private_key = file("${path.module}/az_ssh_key.pem")
    }
  }

  # Upload database restore script to the Droplet
  provisioner "file" {
    source      = "restore_pg_dump.sh"
    destination = "/tmp/restore_pg_dump.sh"
    connection {
      type        = "ssh"
      host        = self.ipv4_address
      user        = "root"
      private_key = file("${path.module}/az_ssh_key.pem")
    }
  }

  # Execute the setup and restore scripts
  provisioner "remote-exec" {
    inline = [
      "sudo mv /tmp/setup_instance.sh /usr/local/bin/setup_instance.sh",
      "sudo chmod +x /usr/local/bin/setup_instance.sh",
      "export DB_HOST='${digitalocean_database_cluster.pg_instance.host}'",
      "export DB_USER='${digitalocean_database_cluster.pg_instance.user}'", # Take user from the cluster
      "export DB_PASS='${digitalocean_database_cluster.pg_instance.password}'",
      "export DB_NAME='${digitalocean_database_db.db_instance.name}'",      # Take DB name from the created database
      "export DB_PORT='${digitalocean_database_cluster.pg_instance.port}'", # Pass the correct port
      "export ACC_KEY='${var.arm_access_key}'",
      "sudo mv /tmp/restore_pg_dump.sh /usr/local/bin/restore_pg_dump.sh",
      "sudo chmod +x /usr/local/bin/restore_pg_dump.sh",
      "sudo -E /usr/local/bin/restore_pg_dump.sh",
      "sudo -E /usr/local/bin/setup_instance.sh"
    ]
    connection {
      type        = "ssh"
      host        = self.ipv4_address
      user        = "root"
      private_key = file("${path.module}/az_ssh_key.pem")
    }
  }

  depends_on = [digitalocean_database_cluster.pg_instance, digitalocean_database_db.db_instance]
}
