#!/bin/bash

set -e

echo "🚀 Starting Full Cloud Native Environment Setup..."

# ====== 1. SYSTEM SETUP ======
echo "🔧 Updating Ubuntu system..."
sudo apt update && sudo apt upgrade -y

echo "🧰 Installing essential packages..."
sudo apt install -y curl apt-transport-https ca-certificates gnupg software-properties-common lsb-release python3 python3-pip git docker.io tmux python3-venv

echo "🐳 Enabling Docker..."
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker $USER

# ====== 2. KUBERNETES TOOLS ======
echo "🔧 Installing kubectl..."
curl -LO "https://dl.k8s.io/release/$(curl -sL https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl && sudo mv kubectl /usr/local/bin/

echo "📦 Installing Kind..."
curl -Lo ./kind https://kind.sigs.k8s.io/dl/latest/kind-linux-amd64
chmod +x kind && sudo mv kind /usr/local/bin/

echo "🎛️ Installing Helm..."
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

echo "🚦 Installing ArgoCD CLI..."
curl -sSL -o argocd https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
chmod +x argocd && sudo mv argocd /usr/local/bin/

# ====== 3. FASTAPI SKELETON (DEV APP) ======
echo "📁 Creating FastAPI Dev App skeleton in ~/fastapi-app..."
mkdir -p ~/fastapi-app
cat <<EOF > ~/fastapi-app/main.py
from fastapi import FastAPI

app = FastAPI()

@app.get("/")
def read_root():
    return {"message": "Hello from FastAPI in your Cloud Native VM!"}
EOF

cat <<EOF > ~/fastapi-app/requirements.txt
fastapi
uvicorn[standard]
EOF

cat <<EOF > ~/fastapi-app/Dockerfile
FROM python:3.10-slim
WORKDIR /app
COPY . .
RUN pip install --no-cache-dir -r requirements.txt
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
EOF

# ====== 4. KIND CLUSTER AUTO-CREATION ======
echo "🔧 Creating local Kind cluster..."
cat <<EOF > kind-config.yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
  - role: control-plane
    extraPortMappings:
      - containerPort: 30000
        hostPort: 30000
EOF

kind create cluster --name dev-cluster --config kind-config.yaml

# ====== 5. MONITORING STACK ======
echo "📊 Installing Prometheus, Grafana, Loki with Helm..."
kubectl create namespace monitoring || true
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

helm install prometheus prometheus-community/prometheus --namespace monitoring
helm install grafana grafana/grafana --namespace monitoring --set adminPassword='admin' --set service.type=NodePort
helm install loki grafana/loki-stack --namespace monitoring

# ====== 6. CASE STUDY 1 - STUDENT TRACKER APP ======
echo "📚 Cloning Student Tracker app repo..."
cd ~
git clone https://github.com/ChisomJude/student-project-tracker.git || true
cd student-project-tracker

echo "🧪 Setting up Python venv and running app locally..."
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt

# ====== 7. DOCKERHUB LOGIN & PUSH ======
echo "🔐 Logging in to DockerHub..."
export DOCKERHUB_USERNAME=bonaventure2025
export DOCKERHUB_PASSWORD=yourdockerhubpassword

echo "$DOCKERHUB_PASSWORD" | docker login -u "$DOCKERHUB_USERNAME" --password-stdin

echo "🐳 Building Docker image for Student Tracker App..."
docker build -t $DOCKERHUB_USERNAME/student-tracker:latest .

echo "🚀 Running Docker container locally..."
docker run -d -p 8000:8000 --env-file .env $DOCKERHUB_USERNAME/student-tracker:latest

echo "📤 Pushing image to DockerHub..."
docker push $DOCKERHUB_USERNAME/student-tracker:latest

# ====== 8. FINAL CHECKS ======
echo ""
echo "✅ SYSTEM STATUS:"
docker --version
kubectl version --client
kind version
helm version
git --version

echo ""
echo "📌 REMINDERS:"
echo " - Log out & log back in for Docker group to apply."
echo " - Student Tracker API Docs: http://<your-vm-ip>:8000/docs"
echo " - Grafana UI (admin/admin): http://localhost:30000"
echo " - Use tmux: tmux new -s dev | tmux attach -t dev"
