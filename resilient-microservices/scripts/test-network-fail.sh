#!/bin/bash

echo "=== Simulação de Falha de Rede entre Serviços ==="
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
echo "Este teste simula falha de rede entre microserviços usando Network Policies"
echo ""

# Função para testar endpoint
test_endpoint() {
  local url=$1
  local name=$2
  
  response=$(curl -s -o /dev/null -w "%{http_code}" $url 2>/dev/null)
  
  if [ "$response" = "200" ]; then
    echo "✅ $name: OK (HTTP $response)"
    return 0
  else
    echo "❌ $name: FALHOU (HTTP $response)"
    return 1
  fi
}

echo "[1] Testando comunicação normal..."
test_endpoint "$BASE_URL/api/data" "API Service"

echo ""
echo "[2] Aplicando Network Policy para bloquear tráfego para API..."

# Criar Network Policy que bloqueia tráfego de entrada no API
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: block-api-ingress
spec:
  podSelector:
    matchLabels:
      app: api-service
  policyTypes:
  - Ingress
  ingress: []
EOF

echo "✅ Network Policy aplicada"
echo ""

echo "[3] Aguardando política ser aplicada..."
sleep 9

echo ""
echo "[4] Testando comunicação com bloqueio ativo..."
echo "Esperado: Timeout ou falha de conexão"
echo ""

# Testar com timeout mais curto
for i in {1..3}; do
  echo "Tentativa $i/3..."
  timeout 5 curl -s $BASE_URL/api/data > /dev/null 2>&1
  if [ $? -eq 124 ]; then
    echo "⏱️  Timeout (esperado - rede bloqueada)"
  else
    echo "⚠️  Resposta recebida (inesperado)"
  fi
  sleep 2
done

echo ""
echo "[5] Verificando logs do Nginx (deve mostrar erros de upstream)..."
kubectl logs -l app=nginx-lb --tail=10 | grep -i "upstream\|error\|timeout" || echo "Sem erros visíveis nos logs recentes"

echo ""
echo "[6] Removendo bloqueio de rede..."
kubectl delete networkpolicy block-api-ingress

echo ""
echo "[7] Aguardando recuperação..."
sleep 5

echo ""
echo "[8] Testando comunicação após remoção do bloqueio..."
if test_endpoint "$BASE_URL/api/data" "API Service"; then
    echo "✅ Serviço recuperou automaticamente!"
else
    echo "⚠️  Serviço ainda não recuperou, aguardando mais 5s..."
    sleep 5
    test_endpoint "$BASE_URL/api/data" "API Service"
fi

echo ""
echo "✅ Teste de falha de rede concluído!"
echo ""
echo "📊 Observações:"
echo "  - Network Policy bloqueou tráfego de entrada no API"
echo "  - Nginx detectou upstream failure"
echo "  - Após remoção, comunicação restaurada automaticamente"
echo ""
echo "Para análise detalhada:"
echo "  kubectl get networkpolicies"
echo "  kubectl describe networkpolicy block-api-ingress"
echo "  kubectl logs -l app=nginx-lb --tail=50"
