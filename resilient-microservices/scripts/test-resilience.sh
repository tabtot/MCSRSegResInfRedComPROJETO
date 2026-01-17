#!/bin/bash

echo "=== Teste de Resiliência ==="
echo ""

# Detectar IP
if kubectl config current-context | grep -q "minikube"; then
    MINIKUBE_IP=$(minikube ip 2>/dev/null)
    BASE_URL="http://$MINIKUBE_IP:30080"
    echo "🔍 Minikube detectado - usando IP: $MINIKUBE_IP"
else
    BASE_URL="http://localhost:30080"
    echo "🔍 Usando localhost"
fi

echo ""

# Função para testar endpoint
test_endpoint() {
  local url=$1
  local name=$2
  
  response=$(curl -s -o /dev/null -w "%{http_code}" $url 2>/dev/null)
  
  if [ "$response" = "200" ]; then
    echo "✅ $name: OK (HTTP $response)"
  else
    echo "❌ $name: FALHOU (HTTP $response)"
  fi
}

echo "[1] Testando disponibilidade inicial..."
test_endpoint "$BASE_URL/api/data" "API Service"
test_endpoint "$BASE_URL/auth/login" "Auth Service (POST)"
test_endpoint "$BASE_URL/" "Dashboard"

echo ""
echo "[2] Verificando réplicas atuais..."
kubectl get pods -l app=api-service -o wide

echo ""
echo "[3] Simulando falha de container (deletando 1 pod do API)..."
API_POD=$(kubectl get pods -l app=api-service -o jsonpath='{.items[0].metadata.name}')
echo "Deletando pod: $API_POD"
date
kubectl delete pod $API_POD

echo ""
echo "[4] Aguardando recuperação automática..."
echo "O Kubernetes deve recriar o pod automaticamente..."
sleep 5

echo "Aguardando pod ficar ready (até 60s)..."
kubectl wait --for=condition=ready pod -l app=api-service --timeout=60s
date
echo ""
echo "[5] Testando disponibilidade após recuperação..."
test_endpoint "$BASE_URL/api/data" "API Service"

echo ""
echo "[6] Verificando réplicas após recuperação..."
kubectl get pods -l app=api-service

echo ""
echo "[7] Verificando HPA (autoscaling)..."
kubectl get hpa

echo ""
echo "[8] Gerando carga para testar autoscaling..."
echo "Enviando 2000 requisições em 10 segundos..."

START_TIME=$(date +%s)

for i in {1..15}; do
  echo "[$i/30] Sending burst of 150 requests..."
  for j in {1..350}; do
    curl -s $BASE_URL/api/data > /dev/null 2>&1 &
  done
  sleep 1
done

wait

END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))

echo "Ataque durou $DURATION segundos"

echo "Aguardando processamento..."
sleep 40

echo ""
echo "[9] Verificando se HPA escalou..."
kubectl get hpa
kubectl get pods -l app=api-service

echo ""
echo "✅ Teste de resiliência concluído!"
echo ""
echo "📊 Métricas para análise:"
echo ""
echo "RTO (Recovery Time Objective):"
echo "  Tempo desde falha até recuperação: ~10-30s"
echo ""
echo "MTTR (Mean Time To Repair):"
echo "  kubectl describe pod  | grep Started"
echo ""
echo "MTTD (Mean Time To Detect):"
echo "  Health checks detectam falha em ~10s"
echo ""
echo "Ver logs de recuperação:"
echo "  kubectl get events --sort-by='.lastTimestamp' | grep api-service"
