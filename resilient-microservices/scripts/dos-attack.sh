#!/bin/bash

echo "=== Simulação de Ataque DoS ==="
echo ""

# Detectar IP
if kubectl config current-context | grep -q "minikube"; then
    MINIKUBE_IP=$(minikube ip 2>/dev/null)
    TARGET_URL="http://$MINIKUBE_IP:30080"
    echo "Minikube detectado - usando IP: $MINIKUBE_IP"
else
    TARGET_URL="http://localhost:30080"
    echo "Usando localhost"
fi

echo ""
echo "Target: $TARGET_URL/api/data"
echo "Rate limit configurado: 100 req/s para API"
echo ""
echo "Iniciando ataque DoS (200 requisições/segundo por 30 segundos)..."
echo "Pressione Ctrl+C para parar"
echo ""

START_TIME=$(date +%s)

for i in {1..30}; do
  echo "[$i/30] Sending burst of 200 requests..."
  for j in {1..1000}; do
    curl -s $TARGET_URL/api/data > /dev/null 2>&1 &
  done
  sleep 1
done

wait

END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))

echo ""
echo "✅ Ataque concluído!"
echo "Duração: ${DURATION}s"
echo "Total de requisições enviadas: ~6000"
echo ""
echo "📊 Verificar impacto:"
echo ""
echo "1. Logs do Nginx (rate limiting):"
echo "   kubectl logs -l app=nginx-lb --tail=50 | grep -i limit"
echo ""
echo "2. Logs centralizados:"
echo "   kubectl port-forward svc/logger-service 5000:5000 &"
echo "   curl http://localhost:5000/stats | jq"
echo ""
echo "3. Status dos pods (verificar se escalou):"
echo "   kubectl get hpa"
echo "   kubectl get pods"
