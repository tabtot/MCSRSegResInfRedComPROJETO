#!/bin/bash

echo "======= Teste de Resiliência ======="
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

# Função para testar endpoint GET
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

# Função para testar endpoint POST
test_post_endpoint() {
    local url=$1
    local name=$2
    local data=$3
    
    response=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$url" \
        -H "Content-Type: application/json" \
        -d "$data" 2>/dev/null)
    
    if [ "$response" = "200" ]; then
        echo "✅ $name: OK (HTTP $response)"
    else
        echo "❌ $name: FALHOU (HTTP $response)"
    fi
}

echo "[1] Testando disponibilidade inicial..."
test_endpoint "$BASE_URL/api/data" "API Service"
test_post_endpoint "$BASE_URL/auth/login" "Auth Service" '{"username":"test", "password":"12345"}'
test_endpoint "$BASE_URL/" "Dashboard"
echo ""

echo "[2] Verificando réplicas atuais..."
kubectl get pods -l app=api-service -o wide
echo ""

echo "[3] Simulando falha de container (A apagar 1 pod do API)..."
API_POD=$(kubectl get pods -l app=api-service -o jsonpath='{.items[0].metadata.name}')
echo "A apagar pod: $API_POD"
START_TIME0=$(date +%s)
kubectl delete pod $API_POD
echo ""

echo "[4] Aguardando recuperação automática..."
echo "O Kubernetes deve recriar o pod automaticamente..."
echo "Aguardando pod ficar ready..."
kubectl wait --for=condition=ready pod -l app=api-service --timeout=60s
END_TIME0=$(date +%s)
DURATION0=$((END_TIME0 - START_TIME0))
echo ""
echo "⏱️  O serviço demorou: $DURATION0 segundos para recuperar."
echo ""

echo "[5] Testando disponibilidade após recuperação..."
test_endpoint "$BASE_URL/api/data" "API Service"
echo ""

echo "[6] Verificando réplicas após recuperação..."
kubectl get pods -l app=api-service
echo ""

echo "[6.1] 60 segundos para metrics-server fazer a leitura do servico"
sleep 60

echo "[7] Verificando HPA (autoscaling)..."
kubectl get hpa
echo ""
echo "========= TESTE DoS ATTACK ============="
echo ""
echo "[8] Gerando carga para testar autoscaling..."

START_TIME=$(date +%s)
PREVIOUS_REPLICAS=$(kubectl get deployment api-service -o jsonpath='{.status.replicas}' 2>/dev/null)
SCALE_DETECTED=0
SCALE_TIMESTAMP=""

for i in {1..30}; do
    # Verificar scaling
    CURRENT_REPLICAS=$(kubectl get deployment api-service -o jsonpath='{.status.replicas}' 2>/dev/null)
    
    if [ "$CURRENT_REPLICAS" != "$PREVIOUS_REPLICAS" ] && [ "$SCALE_DETECTED" -eq 0 ]; then
        SCALE_TIMESTAMP=$(date +%s)
        SCALE_DETECTED=1
        echo ""
        echo "🔼 SCALING DETECTADO em $(date '+%Y-%m-%d %H:%M:%S')"
        echo "   Réplicas: $PREVIOUS_REPLICAS → $CURRENT_REPLICAS"
        echo ""
    fi
    
    echo "[$i/30] Sending burst of 300 requests..."
    for j in {1..300}; do
        curl -s $BASE_URL/api/data > /dev/null 2>&1 &
    done
    
    PREVIOUS_REPLICAS=$CURRENT_REPLICAS
    sleep 1
done

wait
END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))

echo ""
echo "⏱️  Ataque durou $DURATION segundos"
echo "Aguardando processamento..."
sleep 10
echo ""

echo "[9] Verificando se HPA escalou..."
kubectl get hpa
kubectl get pods -l app=api-service
echo ""

echo "✅ Teste de resiliência concluído!"
echo ""
echo "================================================"
echo "📊 RELATÓRIO DE MÉTRICAS"
echo "================================================"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "[TESTE 1] FALHA DE SERVIÇO (POD DELETION)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "🎯 Objetivos:"
echo "   RTO (Recovery Time Objective): < 40 segundos"
echo "   RPO (Recovery Point Objective): 100%"
echo ""
echo "📈 Resultados:"
echo "   MTTD (Mean Time To Detect): Imediato (Kubernetes detecta instantaneamente)"
echo "   MTTR (Mean Time To Repair): $DURATION0 segundos"
echo ""
if [ "$DURATION0" -le 40 ]; then
    echo "   ✅ RTO ATINGIDO: Recuperação em $DURATION0s (< 40s)"
else
    echo "   ❌ RTO NÃO ATINGIDO: Recuperação em $DURATION0s (> 40s)"
fi
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "[TESTE 2] ATAQUE DoS (LOAD TESTING)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "🎯 Objetivos:"
echo "   RTO (Recovery Time Objective): < 60 segundos"
echo "   RPO (Recovery Point Objective): 100%"
echo ""
echo "📊 Carga Gerada:"
echo "   Duração do ataque: $DURATION segundos"
echo "   Requests por burst: 300"
echo "   Número de bursts: 30"
echo "   Total de requests: 9000 pedidos"
echo "   Taxa média: ~$((9000 / DURATION)) req/s"
echo ""
echo "📈 Resultados:"
echo "   MTTD (Mean Time To Detect): ~20 segundos"
echo "   (Metrics-server refresh interval)"
echo ""

if [ "$SCALE_DETECTED" -eq 1 ]; then
    MTTR=$((SCALE_TIMESTAMP - START_TIME))
    echo "   MTTR (Mean Time To Repair): $MTTR segundos para escalar"
    echo ""
    if [ "$MTTR" -le 60 ]; then
        echo "   ✅ RTO ATINGIDO: Scaling em $MTTR s (< 60s)"
    else
        echo "   ⚠️  RTO NÃO ATINGIDO: Scaling em $MTTR s (> 60s)"
    fi
else
    echo "   ⚠️  SCALING NÃO DETECTADO durante o teste"
fi

