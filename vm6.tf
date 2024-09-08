# Fetch the existing SSH key by name
data "digitalocean_ssh_key" "az_ssh_key" {
  name = "az_ssh_key_pem" # Name of your existing SSH key
}

# Create a Droplet in the specified VPC
resource "digitalocean_droplet" "vm_0_6" {
  name     = "tf-droplet-06"
  region   = "fra1"                        # Region for Droplet (e.g., Frankfurt)
  size     = "s-1vcpu-1gb"                 # Droplet size
  image    = "ubuntu-22-04-x64"            # OS image for the Droplet
  vpc_uuid = digitalocean_vpc.fra1-10-0.id # Attach Droplet to the created VPC

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
      agent       = false
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
      agent       = false
      user        = "root"
      private_key = file("${path.module}/az_ssh_key.pem")
    }
  }

  # Execute the setup and restore scripts
  provisioner "remote-exec" {
    inline = [
      "sudo mv /tmp/setup_instance.sh /usr/local/bin/setup_instance.sh",
      "sudo chmod +x /usr/local/bin/setup_instance.sh",
      "sudo mv /tmp/restore_pg_dump.sh /usr/local/bin/restore_pg_dump.sh",
      "sudo chmod +x /usr/local/bin/restore_pg_dump.sh",


      "echo 'export DB_HOST=${nonsensitive(digitalocean_database_cluster.pg_instance.host)}' > /tmp/env_vars.sh",
      "echo 'export DB_USER=${nonsensitive(digitalocean_database_cluster.pg_instance.user)}' >> /tmp/env_vars.sh",
      "echo 'export DB_PASS=${nonsensitive(digitalocean_database_cluster.pg_instance.password)}' >> /tmp/env_vars.sh",
      "echo 'export DB_NAME=${nonsensitive(digitalocean_database_db.db_instance.name)}' >> /tmp/env_vars.sh",
      "echo 'export DB_PORT=${nonsensitive(digitalocean_database_cluster.pg_instance.port)}' >> /tmp/env_vars.sh",
      "echo 'export ACC_KEY=${nonsensitive(var.arm_access_key)}' >> /tmp/env_vars.sh",
      "sudo chmod +x /tmp/env_vars.sh",

      "sudo -E /bin/bash -c 'source /tmp/env_vars.sh && /usr/local/bin/restore_pg_dump.sh'",
      "sudo -E /bin/bash -c 'source /tmp/env_vars.sh && /usr/local/bin/setup_instance.sh'"
    ]
    connection {
      type        = "ssh"
      host        = self.ipv4_address
      agent       = false
      user        = "root"
      private_key = file("${path.module}/az_ssh_key.pem")
    }
  }



  depends_on = [digitalocean_database_cluster.pg_instance, digitalocean_database_db.db_instance]
}

resource "null_resource" "update_dns_webdo7" {
  triggers = {
    endpoint = digitalocean_database_cluster.pg_instance.host
  }


  provisioner "local-exec" {
    command = "python3 update_hetzner.py"
    environment = {
      HETZNER_DNS_KEY     = var.hetzner_dns_key
      NEW_IP              = digitalocean_droplet.vm_0_6.ipv4_address
      HETZNER_RECORD_NAME = "webdo6"
      HETZNER_DOMAIN_NAME = "pam4.com"
    }
  }
  depends_on = [digitalocean_droplet.vm_0_6 ]
}