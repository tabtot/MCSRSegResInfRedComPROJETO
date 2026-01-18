
MINIKUBE_IP=$(minikube ip 2>/dev/null)
BASE_URL="http://$MINIKUBE_IP:30080"

for i in {1..1}; do
    echo "[$i/1] Sending burst of 150 requests..."
    for j in {1..150}; do
        curl -s $BASE_URL/api/data > /dev/null 2>&1 &
    done
    
    sleep 3 
done

for i in {1..1}; do
    echo "[$i/1] Sending burst of 155 requests..."
    for j in {1..155}; do
        curl -s $BASE_URL/api/data > /dev/null 2>&1 &
    done
    
    sleep 3 
done
