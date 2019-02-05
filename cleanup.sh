#!/bin/bash

#kubectl delete --all pods
#kubectl delete --all pods -n istio-system
#kubectl delete --all services
#kubectl delete --all services -n istio-system
#kubectl delete --all virtualservices
#kubectl delete --all virtualservices -n istio-system
#kubectl delete --all gateways
#kubectl delete --all gateways -n istio-system
#kubectl delete --all deployments
#kubectl delete --all deployments -n istio-system

kubectl delete -f bookinfo/bookinfo.yaml
kubectl delete -f ~/istio.yaml

echo "******Deleted Istio******"
sudo minikube delete
echo "******Stopped Minikube******"
docker rm -f $(docker ps -aq)
echo "******Removed all running docker containers******"
#docker rmi $(docker images -aq)
#echo "******Removed all docker images******"