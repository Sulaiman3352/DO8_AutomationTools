ssh-keygen -t ed25519 -f /home/vagrant/.ssh/id_ed25519 -N ""
chown -R vagrant:vagrant /home/vagrant/.ssh/
apt install sshpass -y
# 3. Copy to Node 01
sshpass -p "vagrant" ssh-copy-id -o StrictHostKeyChecking=no -i /home/vagrant/.ssh/id_ed25519.pub vagrant@192.168.56.11

# 4. Copy to Node 02
sshpass -p "vagrant" ssh-copy-id -o StrictHostKeyChecking=no -i /home/vagrant/.ssh/id_ed25519.pub vagrant@192.168.56.12

# 5. Copy to db
sshpass -p "vagrant" ssh-copy-id -o StrictHostKeyChecking=no -i /home/vagrant/.ssh/id_ed25519.pub vagrant@192.168.56.13


