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

sudo k3d cluster create mycluster -p "80:80@loadbalancer" -p "8080:8080@loadbalancer"

sudo kubectl create namespace dev
sudo kubectl create namespace argocd
sudo kubectl apply -n argocd --server-side --force-conflicts -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd
rm argocd-linux-amd64

sudo kubectl patch configmap argocd-cmd-params-cm -n argocd --type merge -p '{"data":{"server.insecure":"true"}}'
sudo kubectl rollout restart deployment argocd-server -n argocd
sudo kubectl apply -f /vagrant/confs/ingress.yaml

sudo kubectl create namespace gitlab
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-4 | bash

helm repo add gitlab https://charts.gitlab.io
helm install --namespace gitlab gitlab gitlab/gitlab \
  --timeout 1800s \
  --set global.hosts.domain="${EXTERNAL_IP}.nip.io" \
  --set global.hosts.externalIP="$EXTERNAL_IP" \
  --set global.hosts.https=false \
  --set nginx-ingress.enabled=false \
  --set prometheus.install=false \
  --set gitlab-runner.install=false \
  --set registry.enabled=false \
  --set global.ingress.configureCertmanager=false \
  --set global.ingress.enabled=false \
  --set global.kas.enabled=false \
  --set global.pages.enabled=false \
  --set global.praefect.enabled=false \
  --set global.grafana.enabled=false \
  --set gitlab.gitlab-exporter.enabled=false \
  --set gitlab.toolbox.enabled=false \
  --set global.appConfig.lfs.enabled=false \
  --set global.appConfig.artifacts.enabled=false \
  --set global.appConfig.uploads.enabled=false \
  --set gitlab.webservice.minReplicas=1 \
  --set gitlab.webservice.maxReplicas=1 \
  --set gitlab.sidekiq.minReplicas=1 \
  --set gitlab.sidekiq.maxReplicas=1 \
  --set gitlab.gitlab-shell.minReplicas=1 \
  --set gitlab.gitlab-shell.maxReplicas=1 \
  --set gitlab.webservice.resources.requests.cpu=800m \
  --set gitlab.webservice.resources.requests.memory=1.5Gi \
  --set gitlab.sidekiq.resources.requests.cpu=300m \
  --set gitlab.sidekiq.resources.requests.memory=800Mi \
  --set gitlab.gitaly.resources.requests.cpu=300m \
  --set gitlab.gitaly.resources.requests.memory=800Mi \
  --set postgresql.resources.requests.cpu=300m \
  --set postgresql.resources.requests.memory=384Mi \
  --set redis.resources.requests.cpu=100m \
  --set redis.resources.requests.memory=128Mi \
  --set gitlab.migrations.resources.requests.cpu=300m \
  --set gitlab.migrations.resources.requests.memory=384Mi \
  --set minio.resources.requests.cpu=100m \
  --set minio.resources.requests.memory=128Mi

sudo kubectl apply -f /vagrant/confs/gitlab.yaml

: '
sudo argocd admin initial-password -n argocd

ROOT_PASS=$(sudo kubectl get secret gitlab-gitlab-initial-root-password -n gitlab -o jsonpath='{.data.password}' | base64 -d)
GITLAB_LB=$(sudo kubectl get svc -n gitlab gitlab-external -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

sudo cp /vagrant/confs/dev.yaml dev.yaml
git add .
git commit -m "feat: dev"
git push

sudo kubectl port-forward dev -n default 8888:8888
'