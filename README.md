# From Manual Configuration to Fully Automated Infrastructure

## Background & Objectives

Imagine you need to deploy a microservices application across 10 production servers. Would you manually SSH into each machine, install Docker, copy configuration files, and hope everything works the same way? That's not just tedious — it's a recipe for human error and inconsistent environments.

This project tackles two critical challenges that every DevOps engineer faces:

1. **Configuration Management** — How do you automate server setup consistently across multiple machines?
2. **Service Discovery** — How do services find and communicate with each other when their IP addresses can change?

The goal was to build a fully automated infrastructure using **Ansible** for configuration management and **Consul** for service discovery, simulating a real-world production environment.

---

## Solution Architecture

### Part 1: Ansible-Based Configuration Management

The first part of the project focused on automating remote node configuration using Ansible. The infrastructure consists of three virtual machines:

```
┌────────────────┐       SSH        ┌────────────────┐
│   manager01    │  ────────────►  │     node01    │
│ (Ansible Ctrl) │                 │  (Docker/App) │
└────────────────┘                 └────────────────┘
        │
        │ SSH
        ▼
┌────────────────┐
│     node02     │
│ (Apache + DB)  │
└────────────────┘
```

- **manager01** — The control node running Ansible
- **node01** — Hosts the microservice application via Docker Compose
- **node02** — Runs Apache web server and PostgreSQL database

### Part 2: Consul Service Discovery

The second part implemented service discovery using Consul, allowing services to find each other dynamically without hardcoded IP addresses:

```
┌─────────────────┐      ┌──────────────────┐      ┌────────────────┐
│  consulserver   │      │       api        │      │       db       │
│                 │      │        |         │      │       |        │
│                 │      │        ▼         │      │       ▼        │
│(Consul  Server) │      │  (hotel-service  │      │  (PostgreSQL   │
│                 │      │   + Consul Agent)│ ◄──► │   + Consul     │
│                 │      │                  │      │    Agent)      │
└─────────────────┘      └──────────────────┘      └────────────────┘
        ▲                          ▲                        ▲
        │                          │                        │
        └──────────────────────────┴────────────────────────┘
              (Client-Server Communication)
              Service Registration & Health Checks
```

- **consulserver** — Runs Consul in server mode, providing the central service registry (UI available on port 8500)
- **api** — Hosts the hotel microservice with Consul client agent; registers itself and discovers the database service via Consul
- **db** — Runs PostgreSQL with Consul client agent; registers the database service for discovery, communicates with Consul server for health checks

---

## Implementation

### Part 1: Ansible Fundamentals

#### Setting Up the Infrastructure

The foundation began with Vagrant to create reproducible virtual machines. Each VM runs Ubuntu 24.04 with 4GB RAM and 2 CPUs, connected via a private network:

```ruby
config.vm.define "manager01" do |manager|
  manager.vm.hostname = "manager01"
  manager.vm.network "private_network", ip: "192.168.56.10"
end

config.vm.define "node01" do |node|
  node.vm.hostname = "node01"
  node.vm.network "private_network", ip: "192.168.56.11"
  node.vm.network "forwarded_port", guest: 8081, host: 8081
end
```

#### SSH Key-Based Authentication

For Ansible to work without interactive password prompts, we generated an SSH key on the manager and distributed it to all nodes:

```bash
# Generate SSH key
ssh-keygen -t rsa -b 4096 -C "ansible@manager" -N ""

# Copy to nodes
ssh-copy-id vagrant@192.168.56.11
ssh-copy-id vagrant@192.168.56.12
```

This enables passwordless SSH access, which is essential for Ansible automation.

#### Ansible Inventory Configuration

The inventory file defines our hosts and groups:

```ini
[managers]
manager01 ansible_host=192.168.56.10

[appnodes]
node01 ansible_host=192.168.56.11

[dbnodes]
node02 ansible_host=192.168.56.12

[all:vars]
ansible_user=vagrant
ansible_python_interpreter=/usr/bin/python3
```

#### Verifying Connectivity

Before running any playbooks, we verify Ansible can communicate with all nodes using the ping module:

```bash
ansible all -m ping
```

This simple test confirms SSH connectivity and Python availability on all target machines.

---

### Part 2: Docker Automation with Ansible

#### The Docker Role

The first major playbook installs Docker on the application node. Instead of using shell scripts, we leverage Ansible's apt module for idempotent package installation:

```yaml
- name: Update apt package cache
  apt:
    update_cache: yes
    cache_valid_time: 3600

- name: Install required packages
  apt:
    name:
      - ca-certificates
      - curl
      - gnupg

- name: Add Docker repository
  apt_repository:
    repo: "deb [arch=amd64 signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu {{ ansible_distribution_release }} stable"

- name: Install Docker packages
  apt:
    name:
      - docker-ce
      - docker-ce-cli
      - containerd.io
      - docker-buildx-plugin
      - docker-compose-plugin

- name: Add vagrant user to docker group
  user:
    name: vagrant
    groups: docker
    append: yes
```

The Docker role ensures consistent Docker installation across any number of nodes by running the same declarative configuration.

#### The Application Role

Once Docker is installed, the application role handles deploying the microservice:

```yaml
- name: Build the microservice from services folder
  command: docker compose build
  args:
    chdir: /home/vagrant/services

- name: Deploy the microservice
  command: docker compose up -d
  args:
    chdir: /home/vagrant/services
```

This role copies the Docker Compose file and source code to the remote node and builds/runs the containers.

---

### Part 3: Multi-Role Playbook

The project required creating three reusable Ansible roles:

#### Role 1: Application

Deploys the microservice application using Docker Compose on node01.

#### Role 2: Apache

Installs and configures the Apache web server on node02:

```yaml
- name: Install Apache
  apt:
    name: apache2
    state: present

- name: Start Apache service
  service:
    name: apache2
    state: started
    enabled: yes
```

#### Role 3: PostgreSQL

Installs PostgreSQL, creates a database, and adds sample records:

```yaml
- name: Install PostgreSQL
  apt:
    name: postgresql
    state: present

- name: Create database
  postgresql_db:
    name: hotels_db

- name: Create user
  postgresql_user:
    name: "{{ db_user }}"
    password: "{{ db_password }}"
    db: hotels_db

- name: Create sample table with data
  community.postgresql.postgresql_query:
    queries:
      - CREATE TABLE IF NOT EXISTS hotels (id SERIAL PRIMARY KEY, name VARCHAR(100), city VARCHAR(100));
      - INSERT INTO hotels (name, city) VALUES ('Grand Hotel', 'Paris'), ('Seaside Resort', 'Miami'), ('Mountain Lodge', 'Denver');
```

#### Playbook Assignment

The final playbook assigns roles strategically:

```yaml
- name: Install Docker on Application Node
  hosts: node01
  roles:
    - docker
    - application

- name: Configure web & Database server on node02
  hosts: node02
  roles:
    - apache
    - postgres
```

This demonstrates Ansible's ability to apply different configurations to different machines from a single playbook.

---

### Part 4: Consul Service Discovery

#### Consul Server Configuration

The Consul server runs in agent mode as a server, providing the central service registry:

```hcl
datacenter = "dc1"
data_dir = "/opt/consul"
log_level = "INFO"
node_name = "consul-server"
server = true
bootstrap_expect = 1

ui_config {
  enabled = true
}

client_addr = "0.0.0.0"
bind_addr = "192.168.56.11"
advertise_addr = "192.168.56.11"

connect {
  enabled = true
}

ports {
  http = 8500
  dns = 8600
}
```

The server listens on port 8500 for the web UI and API, and port 8600 for DNS-based service discovery.

#### Consul Client Configuration

Clients (api and db nodes) run in client mode and connect to the server:

```hcl
datacenter = "dc1"
data_dir = "/opt/consul"
server = false

retry_join = ["192.168.56.11"]

bind_addr = "{{ GetInterfaceIP \"enp0s8\" }}"
advertise_addr = "{{ GetInterfaceIP \"enp0s8\" }}"

connect {
  enabled = true
}
```

The template uses Consul's interpolation to dynamically bind to the correct network interface on each machine.

#### Database Setup Role

The install_db role installs PostgreSQL and creates the hotels database:

```yaml
- name: Install PostgreSQL
  apt:
    name: postgresql
    state: present

- name: Start PostgreSQL
  service:
    name: postgresql
    state: started
    enabled: yes

- name: Create database
  postgresql_db:
    name: hotels_db
```

#### Hotel Service Role

The install_hotels_service role handles the Java application:

```yaml
- name: Copy hotel service source
  synchronize:
    src: files/hotel-service/
    dest: /opt/hotel-service/

- name: Install OpenJDK
  apt:
    name: openjdk-8-jdk
    state: present

- name: Set environment variables
  lineinfile:
    path: /etc/environment
    line: "{{ item }}"
  loop:
    - "POSTGRES_HOST=127.0.0.1"
    - "POSTGRES_PORT=5432"
    - "POSTGRES_DB=hotels_db"
    - "POSTGRES_USER=postgres"
    - "POSTGRES_PASSWORD=password"

- name: Build the application
  command: ./mvnw -DskipTests package
  args:
    chdir: /opt/hotel-service

- name: Run the service
  command: java -jar /opt/hotel-service/target/hotel-service-0.0.1-SNAPSHOT.jar
  daemonize: yes
```

#### Complete Site Playbook

The final playbook orchestrates everything:

```yaml
- name: Install Consul Server
  hosts: ConsulServer
  roles:
    - install_consul_server

- name: Install Consul Client
  hosts: api, db
  roles:
    - install_consul_client

- name: Install Postgresql on db machine
  hosts: db
  roles:
    - install_db
    
- name: Setup api machine
  hosts: api
  roles:
    - install_hotels_service
```

---

## Testing & Verification

### Part 1 Tests

- **Ansible Ping** — Verified SSH connectivity to all nodes
- **Docker Deployment** — Confirmed microservices started successfully on node01
- **Postman Tests** — Ran Newman to execute API tests against the deployed services
- **Apache Verification** — Accessed the web server through the browser
- **PostgreSQL Verification** — Connected to the database and queried sample data

### Part 2 Tests

- **Consul UI** — Accessed at http://localhost:8500 to view registered services
- **CRUD Operations** — Tested Create, Read, Update, Delete on the hotel service API
- **Service Health** — Verified services were properly registered in Consul's catalog

---

## Key Technical Highlights

### Idempotent Automation

Ansible's declarative nature means playbooks can be run multiple times safely. If Docker is already installed, the docker role simply reports "ok" instead of reinstalling.

### Role-Based Organization

Breaking playbooks into reusable roles (docker, application, apache, postgres, install_consul_server, install_consul_client, install_db, install_hotels_service) makes the codebase modular and maintainable.

### Infrastructure as Code

All configuration is version-controlled. Need to recreate the infrastructure? Just run `vagrant up` and `ansible-playbook` — everything deploys automatically.

### Service Discovery Basics

Consul provides the foundation for dynamic microservice architectures. Services register themselves, and other services discover them via DNS or HTTP API, eliminating hardcoded dependencies.

---

## Challenges and Solutions

### Challenge 1: SSH Authentication

**Problem:** Ansible needs passwordless SSH access to remote nodes.

**Solution:** Created shell scripts (key.sh, key+1.sh) that generate SSH keys and distribute them using ssh-copy-id during VM provisioning.

### Challenge 2: Docker Installation Consistency

**Problem:** Installing Docker manually on each VM is error-prone.

**Solution:** Used Ansible's apt module with proper repository configuration to ensure consistent Docker installation across all nodes.

### Challenge 3: Role Ordering

**Problem:** PostgreSQL must be running before the hotel service tries to connect.

**Solution:** Used Ansible's role dependency system and handlers for proper service startup ordering.

### Challenge 4: Consul Networking

**Problem:** Consul agents needed to bind to the correct network interface on different VMs.

**Solution:** Used Consul's template syntax `{{ GetInterfaceIP "enp0s8" }}` to dynamically determine the correct IP address for each node.

### Challenge 5: Environment Configuration

**Problem:** The hotel service needed database connection details without hardcoding IP addresses.

**Solution:** Used Ansible's lineinfile module to set environment variables (POSTGRES_HOST, POSTGRES_PORT, etc.) that the application reads at runtime.

---

## Technologies Used

| Category | Technology |
|----------|------------|
| Virtualization | Vagrant, VirtualBox |
| Configuration Management | Ansible |
| Service Discovery | Consul |
| Container Runtime | Docker |
| Orchestration | Docker Compose |
| Web Server | Apache |
| Database | PostgreSQL |
| Build Tool | Maven |
| Runtime | OpenJDK 8 |

---

## Conclusion

This project demonstrates the essential skills required for modern DevOps engineering. From manually configuring servers to fully automated, idempotent infrastructure as code, the journey covers the complete lifecycle of deploying and managing distributed applications.

Key takeaways include understanding Ansible's declarative model for configuration management, learning how Consul enables dynamic service discovery, and appreciating the importance of infrastructure as code for reproducible deployments.

These skills form the foundation for any cloud-native or DevOps role, where automation, scalability, and reliability are paramount.
