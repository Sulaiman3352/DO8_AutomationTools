datacenter = "dc1"
data_dir = "/opt/consul"
log_level = "INFO"
server = false

# Join the server defined in your Vagrantfile
retry_join = ["192.168.56.11"]

# Dynamically bind to the machine's own private IP
# This allows the same file to be used on both API (192.168.56.12) and DB (192.168.56.13)
bind_addr = "{{ GetInterfaceIP \"enp0s8\" }}"
advertise_addr = "{{ GetInterfaceIP \"enp0s8\" }}"

# Enable Connect for Envoy sidecar proxies
connect {
  enabled = true
}

ports {
  grpc = 8502
}
