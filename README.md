# MCSRSegResInfRedComPROJETO
# Arquitetura Resiliente de Microserviços

## 📦 Pré-requisitos

- Docker
- Kubernetes (minikube)
- kubectl
- openssl

## ⚠️ Iniciar Kubernetes PRIMEIRO

**Antes de executar o setup, certifica-te que o Kubernetes está ativo:**

### Opção 1: Minikube
```bash
minikube start
```

### Verificar se está ativo
```bash
kubectl cluster-info
```

## 🚀 Setup Rápido

### 1. Git clone/download

```bash
git clone <GIT_URL>
```

### 3. Dar permissões de execução aos scripts

```bash
chmod +x scripts/*.sh
chmod +x certs/generate-certs.sh
```

### 4. Deploy do Projeto

```bash
minikube start
```

### 5. Executar setup

```bash
./scripts/setup.sh
```

O script irá:
- ✅ Verificar se Kubernetes está ativo
- ✅ Detectar automaticamente se é Minikube
- ✅ Configurar Docker environment (se Minikube)
- ✅ Gerar certificados TLS
- ✅ Construir todas as imagens Docker no ambiente correto
- ✅ Limpar deployments antigos

### 6. Deploy no Kubernetes

```bash
./scripts/deploy.sh
```

### 7. Verificar status

```bash
kubectl get pods
kubectl get services
kubectl get hpa
```

### 8. Metrics-server e Dashboard

```bash
minikube addons enable metrics-server
```

```bash
minikube addons enable dashboard
```
**Acesso ao Dashboard**
```bash
minikube dashboard
```


## 🌐 Acesso ao Sistema

- **Dashboard**: http://localhost:30080
- **HTTPS**: https://localhost:30443
- **API**: http://localhost:30080/api/data
- **Auth**: http://localhost:30080/auth/login

## 📊 Logs Centralizados

```bash
# Port forward para o logger
kubectl port-forward svc/logger-service 5000:5000

# Ver logs
curl http://localhost:5000/logs

# Ver estatísticas
curl http://localhost:5000/stats

# Filtrar logs
curl "http://localhost:5000/logs?service=api-service&limit=10"
```

## 🧪 Testes

### Teste de disponibilidade
```bash
curl http://localhost:30080/api/data
curl http://localhost:30080/
```

### Simular ataque DoS
```bash
./scripts/dos-attack.sh
```

### Testar resiliência
```bash
./scripts/test-resilience.sh
```
Guardar output do teste:
```bash
./scripts/test-resilience.sh >> output.txt
```


### Simular falha manual
```bash
# Apagar um pod
kubectl delete pod <nome-do-pod>

#ou colocar réplcias a 0
kubectl scale deployment api-service --replicas=5

# Verificar recuperação automática
kubectl get pods -w
```

## 🔍 Verificação

### Health Checks
```bash
kubectl get pods -o wide
kubectl describe pod <pod-name> | grep -A 10 "Liveness\|Readiness"
```

### TLS entre serviços
```bash
kubectl exec -it <api-pod-name> -- ls -la /app/*.pem
```

### Rate Limiting
```bash
# Ver logs do Nginx
kubectl logs -l app=nginx-lb --tail=50 | grep "limiting requests"
```

### Réplicas
```bash
kubectl get deployment
# Deve mostrar 3/3 réplicas para cada serviço
```

## 🛠️ Comandos Úteis

```bash
# Ver logs de todos os pods de um serviço
kubectl logs -l app=api-service --all-containers=true

# Escalar manualmente
kubectl scale deployment api-service --replicas=5

# Reiniciar deployment
kubectl rollout restart deployment/api-service

# Ver configuração do HPA
kubectl describe hpa api-service-hpa

# Limpar tudo
kubectl delete -f k8s/
```

## 📁 Estrutura do Projeto

```
resilient-microservices/
├── microservices/
│   ├── api-service/        # Microserviço API REST
│   ├── auth-service/       # Microserviço Autenticação
│   └── dashboard-service/  # Microserviço Dashboard
├── monitoring/             # Logger centralizado
├── nginx/                  # Load balancer + Rate limiting
├── k8s/                    # Manifests Kubernetes
├── certs/                  # Certificados TLS
└── scripts/                # Scripts de setup e testes
```

## 📝 Notas

- Os certificados TLS são auto-assinados (apenas para demo)
- HPA configurado para escalar entre 3-10 réplicas
- Todos os containers executam como utilizador não-root (UID 1000)

### Limpar tudo e recomeçar

```bash
# Apagar todos os recursos
kubectl delete -f k8s/

# Aguardar terminar
kubectl get pods

# Re-executar deploy
./scripts/deploy.sh
```
 
