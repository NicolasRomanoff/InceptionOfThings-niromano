curl -sfL https://get.k3s.io | sh -s - --node-ip 192.168.56.110

curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"

sudo cat /var/lib/rancher/k3s/server/node-token > /vagrant/token