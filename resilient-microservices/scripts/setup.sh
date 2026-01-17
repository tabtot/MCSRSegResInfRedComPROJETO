#!/bin/bash

echo "=== Setup do Projeto de Microserviços Resilientes ==="

# Verificar Kubernetes primeiro
echo "[1/7] Checking Kubernetes..."
if ! kubectl cluster-info &> /dev/null; then
    echo ""
    echo "❌ Kubernetes não está em execução!"
    echo ""
    echo "Por favor, inicia o Kubernetes antes de continuar:"
    echo ""
    echo "  Docker Desktop: Ativar Kubernetes nas Settings"
    echo "  Minikube: minikube start"
    echo ""
    echo "Depois executa novamente: ./scripts/setup.sh"
    exit 1
fi

echo "✅ Kubernetes está ativo"

# Detectar se é Minikube e ativar metrics-server
if kubectl config current-context | grep -q "minikube"; then
    echo ""
    echo "🔍 Minikube detectado!"
    echo "Configurando Docker environment..."
    eval $(minikube docker-env)
    echo "✅ Usando Docker do Minikube"
    
    echo ""
    echo "[2/7] Enabling metrics-server for HPA..."
    minikube addons enable metrics-server
    echo "✅ Metrics server enabled"
else
    echo ""
    echo "[2/7] Checking metrics-server..."
    if ! kubectl get deployment metrics-server -n kube-system &> /dev/null; then
        echo "⚠️  Metrics server não encontrado. HPA pode não funcionar corretamente."
        echo "Para instalar: kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml"
    else
        echo "✅ Metrics server está instalado"
    fi
fi

# Criar certificados TLS
echo "[3/7] Generating TLS certificates..."
cd certs
bash generate-certs.sh
cd ..

# Copiar certificados para cada microserviço
echo "[4/7] Copying certificates to microservices..."
mkdir -p microservices/api-service/certs
mkdir -p microservices/auth-service/certs
mkdir -p microservices/dashboard-service/certs
mkdir -p nginx/certs

cp certs/cert.pem microservices/api-service/certs/
cp certs/key.pem microservices/api-service/certs/
cp certs/cert.pem microservices/auth-service/certs/
cp certs/key.pem microservices/auth-service/certs/
cp certs/cert.pem microservices/dashboard-service/certs/
cp certs/key.pem microservices/dashboard-service/certs/
cp certs/cert.pem nginx/certs/
cp certs/key.pem nginx/certs/

# Build Docker images
echo "[5/7] Building Docker images..."
echo "This may take a few minutes..."

docker build -t api-service:latest ./microservices/api-service
docker build -t auth-service:latest ./microservices/auth-service
docker build -t dashboard-service:latest ./microservices/dashboard-service
docker build -t logger-service:latest ./monitoring
docker build -t nginx-lb:latest ./nginx

# Verificar imagens
echo "[6/7] Verifying Docker images..."
docker images | grep -E "api-service|auth-service|dashboard-service|logger-service|nginx-lb"

echo ""
echo "[7/7] Cleanup old deployments (if any)..."
kubectl delete -f k8s/ 2>/dev/null || echo "No previous deployments found"

echo ""
echo "✅ Setup completo!"
echo ""
