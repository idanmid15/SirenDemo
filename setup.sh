#!/bin/bash

function check_pod_readiness() {
	PODS=$(kubectl get pods --all-namespaces | awk 'NR > 1 {print $4}')
	NUM_PODS=0
	NUM_READY_PODS=0
	for pod in $PODS; do
		if [[($pod =~ "Running") || ($pod =~ "Completed")]]
		then 
			((NUM_READY_PODS++))
        fi
        ((NUM_PODS++))
	done
	echo $(($NUM_READY_PODS * 100 / $NUM_PODS))
}

function wait_for_all_pod_completion() {
	READINESS=0
	while [[ ${READINESS} -lt 100 ]]
	do
		echo "Preparing all pods, current pod readiness is $READINESS%"
		sleep 10
		READINESS=$(check_pod_readiness)
	done
}

# Have to run minikube as root since using the none vm-driver
sudo minikube start --vm-driver=none --memory=4096 --cpus=3
echo "Waiting for initial bare Kubernetes cluster to form"
sleep 60
wait_for_all_pod_completion
echo "*******All system pods of the Kubernetes cluster are now running*******"
echo "**************************************************************************"

helm template --set kiali.enabled=true istio-1.0.5/install/kubernetes/helm/istio \
 --name istio \
 --namespace istio-system > $HOME/istio.yaml

kubectl create namespace istio-system
kubectl apply -f $HOME/istio.yaml

wait_for_all_pod_completion

# Allow pods to send external traffic
helm template istio-1.0.5/install/kubernetes/helm/istio \
 --set kiali.enabled=true \
 --name istio \
 --namespace istio-system \
 --set global.proxy.includeIPRanges="10.0.0.1/24" \
 -x templates/sidecar-injector-configmap.yaml | kubectl apply -f -

echo "*******Installed Istio*******"
echo "**************************************************************************"

echo "***Creating the image for the credit card DB***"
cd creditcards
docker build -f DockerfileForDB -t creditcard_db .
cd ../attackers/overauthorized
echo "***Creating the image for the over authorized attacker***"
docker build -f DockerfileForOverAuthAttacker -t overauthattacker .
cd ../..
echo "*******Finished creating all images the image*******"
echo "**************************************************************************"

echo "***Setting up the bookinfo application***"
kubectl label namespace default istio-injection=enabled
kubectl apply -f bookinfo/bookinfo.yaml
kubectl apply -f bookinfo/bookinfo-gateway.yaml


wait_for_all_pod_completion

INGRESS_PORT=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="http2")].nodePort}')
INGRESS_HOST=$(sudo minikube ip)
GATEWAY_URL=${INGRESS_HOST}:${INGRESS_PORT}

echo "*******Created bookinfo basic application - currently launching*******"
echo "*******Product page url is http://$GATEWAY_URL/productpage*******"
curl http://${GATEWAY_URL}/productpage
echo "**************************************************************************"

echo "*******Launching ElasticSearch, Fluentd and Kibana*******"
kubectl apply -f logging/logging-stack.yaml
wait_for_all_pod_completion
ELASTIC_IP=$(kubectl -n logging get service -l app=elasticsearch -o jsonpath='{.items[0].spec.clusterIP}')
ELASTIC_PORT=$(kubectl -n logging get service -l app=elasticsearch -o jsonpath='{.items[0].spec.ports[0].port}')
echo "**************************************************************************"

echo "*******Setting up log entries for service communication*******"
kubectl apply -f logging/logentries.yaml
wait_for_all_pod_completion
#kubectl apply -f attackers/overauthorized/over_authorized_attacker.yaml
# TODO add script to configure the kube-api server to verbose
# In order to turn the kube-api to verbose in minikube, you will need to change the file
# /etc/kubernetes/manifests/kube-apiserver.yaml and add a --v 4 flag to the kube-api call



