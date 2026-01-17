#!/bin/bash

echo "=== Deploy no Kubernetes ==="

# Deploy de todos os serviços
echo "[1/5] Deploying logger service..."
kubectl apply -f k8s/logger-deployment.yaml

echo "[2/5] Deploying API service..."
kubectl apply -f k8s/api-deployment.yaml

echo "[3/5] Deploying Auth service..."
kubectl apply -f k8s/auth-deployment.yaml

echo "[4/5] Deploying Dashboard service..."
kubectl apply -f k8s/dashboard-deployment.yaml

echo "[5/5] Deploying Nginx load balancer..."
kubectl apply -f k8s/nginx-deployment.yaml

# Aguardar pods ficarem ready com timeout maior
echo ""
echo "Waiting for pods to be ready (this may take 1-2 minutes)..."
echo ""

# Logger primeiro (sem TLS, mais simples)
echo "Checking logger-service..."
if kubectl wait --for=condition=ready pod -l app=logger-service --timeout=120s 2>/dev/null; then
    echo "✅ Logger ready"
else
    echo "⚠️  Logger not ready yet. Checking status..."
    kubectl get pods -l app=logger-service
    kubectl logs -l app=logger-service --tail=20 2>/dev/null || echo "No logs yet"
fi

echo ""
echo "Checking api-service..."
if kubectl wait --for=condition=ready pod -l app=api-service --timeout=120s 2>/dev/null; then
    echo "✅ API ready"
else
    echo "⚠️  API not ready yet. Checking status..."
    kubectl get pods -l app=api-service
fi

echo ""
echo "Checking auth-service..."
if kubectl wait --for=condition=ready pod -l app=auth-service --timeout=120s 2>/dev/null; then
    echo "✅ Auth ready"
else
    echo "⚠️  Auth not ready yet. Checking status..."
    kubectl get pods -l app=auth-service
fi

echo ""
echo "Checking dashboard-service..."
if kubectl wait --for=condition=ready pod -l app=dashboard-service --timeout=120s 2>/dev/null; then
    echo "✅ Dashboard ready"
else
    echo "⚠️  Dashboard not ready yet. Checking status..."
    kubectl get pods -l app=dashboard-service
fi

echo ""
echo "Checking nginx-lb..."
if kubectl wait --for=condition=ready pod -l app=nginx-lb --timeout=120s 2>/dev/null; then
    echo "✅ Nginx ready"
else
    echo "⚠️  Nginx not ready yet. Checking status..."
    kubectl get pods -l app=nginx-lb
fi

echo ""
echo "=== Current Status ==="
echo ""
kubectl get pods
echo ""
kubectl get services
echo ""
kubectl get hpa
echo ""

# Verificar se há pods com problemas
FAILED_PODS=$(kubectl get pods --field-selector=status.phase!=Running,status.phase!=Succeeded -o name 2>/dev/null | wc -l)

# Detectar ambiente
MINIKUBE_IP=""
if kubectl config current-context | grep -q "minikube"; then
    MINIKUBE_IP=$(minikube ip 2>/dev/null)
fi

if [ "$FAILED_PODS" -gt 0 ]; then
    echo "⚠️  Alguns pods têm problemas. Para diagnosticar:"
    echo ""
    echo "  kubectl get pods                    # Ver status"
    echo "  kubectl describe pod      # Ver detalhes"
    echo "  kubectl logs              # Ver logs"
    echo ""
    echo "Problemas comuns:"
    echo "  - ImagePullBackOff: Execute './scripts/setup.sh' novamente"
    echo "  - CrashLoopBackOff: Verifique logs com 'kubectl logs '"
else
    echo "✅ Deploy completo! Todos os pods estão running."
    echo ""
    echo "🌐 ACESSO AO SISTEMA:"
    echo ""
    
    if [ -n "$MINIKUBE_IP" ]; then
        echo "  Minikube IP detectado: $MINIKUBE_IP"
        echo ""
        echo "  Dashboard:  http://$MINIKUBE_IP:30080"
        echo "  HTTPS:      https://$MINIKUBE_IP:30443"
        echo ""
        echo "  API:        http://$MINIKUBE_IP:30080/api/data"
        echo "  Auth:       http://$MINIKUBE_IP:30080/auth/login"
        echo ""
        echo "  Ou use:     minikube service nginx-lb"
    else
        echo "  Dashboard:  http://localhost:30080"
        echo "  HTTPS:      https://localhost:30443"
        echo ""
        echo "  API:        http://localhost:30080/api/data"
        echo "  Auth:       http://localhost:30080/auth/login"
    fi
    
    echo ""
    echo "📊 LOGS CENTRALIZADOS:"
    echo "  kubectl port-forward svc/logger-service 5000:5000"
    echo "  curl http://localhost:5000/logs | jq"
    echo "  curl http://localhost:5000/stats | jq"
    echo ""
    echo "🧪 TESTES:"
    echo "  ./scripts/test-resilience.sh"
    echo "  ./scripts/dos-attack.sh"
fi
