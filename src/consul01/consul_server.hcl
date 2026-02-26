datacenter = "dc1"
data_dir = "/opt/consul"
log_level = "INFO"
node_name = "consul-server"
server = true
bootstrap_expect = 1

# Enable the UI so you can view it at localhost:8500
ui_config {
  enabled = true
}

# Allow access from anywhere (needed for the UI port forwarding to work)
client_addr = "0.0.0.0"

# Bind to the internal Vagrant network IP (192.168.56.11)
bind_addr = "192.168.56.11"
advertise_addr = "192.168.56.11"

# Connect services to this agent
connect {
  enabled = true
}


ports {
  http = 8500
  dns = 8600
}
