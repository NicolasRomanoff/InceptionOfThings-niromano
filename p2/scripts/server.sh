curl -sfL https://get.k3s.io | sh -s - --node-ip 192.168.56.110

sudo kubectl apply -f /vagrant/confs/app-one.yaml
sudo kubectl apply -f /vagrant/confs/app-two.yaml
sudo kubectl apply -f /vagrant/confs/app-three.yaml
sudo kubectl apply -f /vagrant/confs/ingress.yaml
