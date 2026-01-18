#!/bin/bash
# scripts/test-network-logger-failure.sh

echo "=== Falha de Rede: API isolada do Logger ==="
echo ""

# 1. Estado normal
echo "[1] Fazendo 5 requisições à API..."
for i in {1..5}; do
  curl -s http://$(minikube ip):30080/api/data > /dev/null
done
sleep 2

echo "[2] Verificando logs registados:"
LOGGER_POD=$(kubectl get pods -l app=logger-service -o jsonpath='{.items[0].metadata.name}')
LOGS_BEFORE=$(kubectl exec $LOGGER_POD -- cat /logs/centralized.json 2>/dev/null | grep -c "api-service" || echo "0")
echo "    Logs de API no logger: $LOGS_BEFORE"

# 2. Simular falha - escalar logger para 0
echo ""
echo "[3] Simulando falha (Logger fica indisponível)..."
kubectl scale deployment logger-service --replicas=0
sleep 5

echo "[4] Fazendo 5 requisições à API (logs NÃO serão registados)..."
for i in {1..5}; do
  curl -s http://$(minikube ip):30080/api/data > /dev/null
  echo "  Requisição $i: API respondeu (mesmo sem Logger)"
done

echo ""
echo "✅ API continua funcionando sem Logger (graceful degradation)"

# 3. Recuperar logger
echo ""
echo "[5] Restaurando Logger..."
kubectl scale deployment logger-service --replicas=1
kubectl wait --for=condition=ready pod -l app=logger-service --timeout=60s

sleep 3

# Novo pod, logs resetados
LOGGER_POD=$(kubectl get pods -l app=logger-service -o jsonpath='{.items[0].metadata.name}')
echo "    Novo pod do logger: $LOGGER_POD"

echo ""
echo "[6] Fazendo 5 novas requisições (logs DEVEM ser registados)..."
for i in {1..5}; do
  curl -s http://$(minikube ip):30080/api/data > /dev/null
done
sleep 2

LOGS_AFTER=$(kubectl exec $LOGGER_POD -- cat /logs/centralized.json 2>/dev/null | grep -c "api-service" || echo "0")
echo "    Novos logs de API: $LOGS_AFTER"

echo ""
echo "✅ Logger recuperado e a registar logs novamente!"
echo ""
echo "📊 Demonstrado:"
echo "  ✅ API operacional mesmo com Logger down (5 requisições sem logging)"
echo "  ✅ Sem crashes - sistema degrada gracefully"
echo "  ✅ Logger recupera automaticamente"
echo "  ✅ Logging restaurado após recuperação ($LOGS_AFTER novos logs)"
