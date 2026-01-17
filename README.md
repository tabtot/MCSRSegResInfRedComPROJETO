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

### Simular falha manual
```bash
# Apagar um pod
kubectl delete pod <nome-do-pod>

# Verificar recuperação automática
kubectl get pods -w
```

## 📈 Métricas de Resiliência

### RTO (Recovery Time Objective)
```bash
# Tempo de recuperação após falha
kubectl get events --sort-by='.lastTimestamp'
```

### MTTR (Mean Time To Repair)
```bash
# Ver tempo de restart nos logs
kubectl describe pod <pod-name>
```

### Autoscaling em ação
```bash
# Gerar carga
for i in {1..1000}; do curl http://localhost:30080/api/data & done

# Observar scaling
kubectl get hpa -w
```

## 🔍 Verificação de Requisitos

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

## 🔧 Troubleshooting

### Erro: "connection refused" ao executar setup.sh

**Problema**: Kubernetes não está em execução

**Solução**:
```bash
# Docker Desktop
# Ir para Settings → Kubernetes → Enable Kubernetes

# Minikube
minikube start

# Verificar
kubectl cluster-info
```

### Pods ficam em "ImagePullBackOff" ou "ErrImageNeverPull"

**Problema**: Kubernetes não encontra as imagens Docker (comum no Minikube)

**Solução AUTOMÁTICA** (recomendada):
```bash
# O script setup.sh já detecta Minikube automaticamente!
# Basta executar:
./scripts/setup.sh

# Depois:
./scripts/deploy.sh
```

**Solução MANUAL** (se a automática não funcionar):
```bash
# 1. Configurar Docker do Minikube
eval $(minikube docker-env)

# 2. Verificar que estás no ambiente correto
docker images | grep minikube

# 3. Rebuild das imagens
docker build -t api-service:latest ./microservices/api-service
docker build -t auth-service:latest ./microservices/auth-service
docker build -t dashboard-service:latest ./microservices/dashboard-service
docker build -t logger-service:latest ./monitoring
docker build -t nginx-lb:latest ./nginx

# 4. Verificar imagens
docker images | grep -E "api-service|auth-service"

# 5. Re-deploy
kubectl delete -f k8s/
./scripts/deploy.sh
```

### Pods em "CrashLoopBackOff"

**Problema**: Container está a falhar ao iniciar

**Solução**:
```bash
# Ver logs do pod
kubectl logs <pod-name>

# Verificar certificados
kubectl exec -it <pod-name> -- ls -la /app/*.pem

# Se faltarem certificados, re-executar setup
./scripts/setup.sh
```

### "Error from server (NotFound): services not found"

**Problema**: Serviços ainda não foram criados

**Solução**:
```bash
# Re-executar deploy
./scripts/deploy.sh

# Verificar
kubectl get services
```

### Não consigo aceder a localhost:30080

**Problema 1**: Serviço ainda não está ready
```bash
# Aguardar todos os pods ficarem ready
kubectl get pods -w
```

**Problema 2**: Minikube usa IP diferente
```bash
# Descobrir IP do Minikube
minikube ip

# Usar esse IP em vez de localhost
curl http://<minikube-ip>:30080
```

**Problema 3**: Port-forward necessário
```bash
kubectl port-forward svc/nginx-lb 8080:80
# Aceder em http://localhost:8080
```

### HPA mostra "<unknown>" para métricas

**Problema**: Metrics server não está instalado

**Solução (Minikube)**:
```bash
minikube addons enable metrics-server
```

**Solução (Docker Desktop)**:
```bash
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
```

### Limpar tudo e recomeçar

```bash
# Deletar todos os recursos
kubectl delete -f k8s/

# Aguardar terminar
kubectl get pods

# Re-executar deploy
./scripts/deploy.sh
```
 
