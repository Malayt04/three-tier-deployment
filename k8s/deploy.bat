@echo off
echo Creating three-tier namespace...
kubectl apply -f namespace.yaml

echo Waiting for namespace to be ready...
timeout /t 5 /nobreak >nul

echo Deploying database components...
kubectl apply -f database/ -n three-tier

echo Waiting for database to be ready...
timeout /t 10 /nobreak >nul

echo Deploying backend components...
kubectl apply -f backend/ -n three-tier

echo Waiting for backend to be ready...
timeout /t 10 /nobreak >nul

echo Deploying frontend components...
kubectl apply -f frontend/ -n three-tier

echo Deploying ingress...
kubectl apply -f ingress.yml -n three-tier

echo All components deployed successfully!
echo To check the status of your deployments, run:
echo kubectl get pods -n three-tier
echo kubectl get services -n three-tier
echo kubectl get ingress -n three-tier