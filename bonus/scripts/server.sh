sudo apt update
sudo apt install ca-certificates curl -y
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc
sudo tee /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: $(. /etc/os-release && echo "$VERSION_CODENAME")
Components: stable
Signed-By: /etc/apt/keyrings/docker.asc
EOF
sudo apt update
sudo apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y

curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash

curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

sudo k3d cluster create mycluster -p "80:80@loadbalancer"

sudo kubectl create namespace dev
sudo kubectl create namespace argocd
sudo kubectl apply -n argocd --server-side --force-conflicts -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd
rm argocd-linux-amd64

sudo kubectl patch configmap argocd-cmd-params-cm -n argocd --type merge -p '{"data":{"server.insecure":"true"}}'
sudo kubectl rollout restart deployment argocd-server -n argocd
sudo kubectl apply -f /vagrant/confs/ingress.yaml

# For get the password of argocd with "admin" username
# argocd admin initial-password -n argocd

sudo kubectl create namespace gitlab
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-4 | bash

helm repo add gitlab https://charts.gitlab.io
helm install --namespace gitlab gitlab gitlab/gitlab \
  --timeout 600s \
  --set global.hosts.domain=localhost \
  --set global.ingress.configureCertmanager=false \
  --set nginx-ingress.enabled=false
