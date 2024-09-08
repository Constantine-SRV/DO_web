# Define a Load Balancer (ALB) for the two droplets
resource "digitalocean_loadbalancer" "alb" {
  name   = "fra1-load-balancer-01"
  region = "fra1"
  size   = "lb-small"

  forwarding_rule {
    entry_port     = 443
    entry_protocol = "https"
    target_port    = 443
    target_protocol = "https"
    tls_passthrough = true
  }

  healthcheck {
    protocol = "https"
    port     = 443
    path     = "/"
    check_interval_seconds = 10
    response_timeout_seconds = 5
    healthy_threshold = 3
    unhealthy_threshold = 3
  }

  droplet_ids = [
    digitalocean_droplet.vm_0_7.id,
    digitalocean_droplet.vm_0_6.id
  ]

  depends_on = [digitalocean_droplet.vm_0_7, digitalocean_droplet.vm_0_6]
}

# Update DNS record for the load balancer using Hetzner API
resource "null_resource" "update_dns_alb" {
  provisioner "local-exec" {
    command = "python3 update_hetzner.py"
    environment = {
      HETZNER_DNS_KEY     = var.hetzner_dns_key
      NEW_IP              = digitalocean_loadbalancer.alb.ipv4_address
      HETZNER_RECORD_NAME = "webdo"
      HETZNER_DOMAIN_NAME = "pam4.com"
    }
  }

  depends_on = [digitalocean_loadbalancer.alb]
}
