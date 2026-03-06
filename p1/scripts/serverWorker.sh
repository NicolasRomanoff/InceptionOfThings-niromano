TOKEN=$(sudo cat /vagrant/token)

curl -sfL https://get.k3s.io | K3S_URL=https://192.168.56.110:6443 K3S_TOKEN=$TOKEN sh - --node-ip 192.168.56.111