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
	sleep 10
	READINESS=$(check_pod_readiness)
	while [ $READINESS -lt 100 ]
	do
		echo "Preparing all pods, current pod readiness is $READINESS%"
		sleep 30
		READINESS=$(check_pod_readiness)
	done
}


sudo minikube start --vm-driver=none --memory=4096 --cpus=3
wait_for_all_pod_completion
echo "*******All system pods of the Kubernetes cluster are now running*******"
echo "**************************************************************************"

kubectl apply -f istio-1.0.3/install/kubernetes/helm/istio/templates/crds.yaml
kubectl apply -f istio-1.0.3/install/kubernetes/istio-demo-auth.yaml
wait_for_all_pod_completion
echo "*******Installed Istio*******"
echo "**************************************************************************"

echo "***Setting up the bookinfo application***"
kubectl label namespace default istio-injection=enabled
kubectl apply -f istio-1.0.3/samples/bookinfo/platform/kube/bookinfo.yaml
kubectl apply -f istio-1.0.3/samples/bookinfo/networking/bookinfo-gateway.yaml
wait_for_all_pod_completion
INGRESS_PORT=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="http2")].nodePort}')
INGRESS_HOST=$(sudo minikube ip)
GATEWAY_URL=$INGRESS_HOST:$INGRESS_PORT
echo "*******Created bookinfo basic application - currently launching*******"
echo "*******Gateway url is $GATEWAY_URL*******"
curl http://$GATEWAY_URL/productpage
echo "**************************************************************************"

echo "*******Launching ElasticSearch, Fluentd and Kibana*******"
kubectl apply -f logging-stack.yaml
wait_for_all_pod_completion
ELASTIC_IP=$(kubectl -n logging get service -l app=elasticsearch -o jsonpath='{.items[0].spec.clusterIP}')
ELASTIC_PORT=$(kubectl -n logging get service -l app=elasticsearch -o jsonpath='{.items[0].spec.ports[0].port}')
echo "**************************************************************************"

echo "*******Setting up log entries for service communication*******"
kubectl apply -f logentries.yaml

echo "*******Creating the docker container image for the pod-communicator*******"
#docker build -t comtesting .
echo "**************************************************************************"

echo "*******Creating the config for the pod-communicator*******"
cat <<EOF | kubectl apply -f -
# Fluentd ConfigMap, contains config files.
kind: ConfigMap
apiVersion: v1
data:
  elasticsearch-ip: "$ELASTIC_IP"
  elasticsearch-port: "$ELASTIC_PORT"
metadata:
  name: pod-communicator-config
EOF
echo "*******Creating the pod-communicator*******"
# kubectl apply -f pod-communicator.yaml
echo "**************************************************************************"
