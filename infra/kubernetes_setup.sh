#!/bin/bash

LOG_FILE="log"

echo "Starting minikube cluster"
minikube start --vm-driver=kvm2 > $LOG_FILE

echo "Building image"
eval $(minikube docker-env) > $LOG_FILE
docker build -t factorial:app . > $LOG_FILE

echo "Starting app"
kubectl run factorial --image=factorial:app --image-pull-policy=Never > $LOG_FILE

sleep 10

echo "Starting service"
kubectl expose deployment/factorial --type="NodePort" --target-port=5000 --port=8080 > $LOG_FILE

sleep 10

export NODE_PORT=$(kubectl get services/factorial -o go-template='{{(index .spec.ports 0).nodePort}}')

curl $(minikube ip):$NODE_PORT/run/500

sleep 10

minikube stop
minikube delete
