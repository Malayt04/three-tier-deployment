# Three-Tier Application Deployment on EKS

This project contains the Kubernetes configurations for deploying a three-tier application (frontend, backend, database) on Amazon EKS.

## Architecture

The application consists of three main components:

1. **Frontend**: A React-based user interface
2. **Backend**: A Node.js API server
3. **Database**: MongoDB for data storage

The services communicate as follows:
- Frontend makes API calls to the Backend
- Backend connects to MongoDB for data persistence
- Ingress routes external traffic to the appropriate services

## Project Structure

```
three-tier-deployment/
├── Application-Code/
│   ├── backend/          # Node.js backend application
│   └── frontend/         # React frontend application
├── k8s/                  # Kubernetes configurations
│   ├── namespace.yaml    # Namespace configuration
│   ├── database/         # MongoDB configuration
│   ├── backend/          # Backend application configuration
│   ├── frontend/         # Frontend application configuration
│   ├── ingress.yml       # Ingress configuration
│   ├── kustomization.yaml # Kustomize configuration
│   ├── deploy.sh         # Linux deployment script
│   └── deploy.bat        # Windows deployment script
├── eks.yml               # EKS cluster configuration
└── README.md             # This file
```

## Prerequisites

- AWS account with necessary permissions
- AWS CLI configured
- kubectl installed and configured
- eksctl installed (optional)
- Docker installed for building images

## EKS Cluster Setup

If you need to create an EKS cluster, you can use the provided `eks.yml` or create one using eksctl:

```bash
eksctl create cluster \
  --name three-tier-cluster \
  --region <your-region> \
  --nodegroup-name standard-workers \
  --node-type t3.medium \
  --nodes 3 \
  --nodes-min 1 \
  --nodes-max 5
```

## AWS Load Balancer Controller Setup

For the ingress to work properly, you'll need to install the AWS Load Balancer Controller:

```bash
# Add the AWS Load Balancer Controller to your cluster
eksctl create addon --name aws-load-balancer-controller --cluster <your-cluster-name> --region <your-region>
```

## Docker Images

Before deploying to Kubernetes, you need to build and push Docker images:

1. Build and push the frontend image:
   ```bash
   cd Application-Code/frontend/
   docker build -t <your-registry>/frontend:latest .
   docker push <your-registry>/frontend:latest
   ```

2. Build and push the backend image:
   ```bash
   cd Application-Code/backend/
   docker build -t <your-registry>/backend:latest .
   docker push <your-registry>/backend:latest
   ```

Update the image names in the Kubernetes deployment files accordingly.

## Deployment

### Option 1: Using Deployment Scripts

**On Windows:**
```cmd
cd k8s
deploy.bat
```

**On Linux:**
```bash
cd k8s
chmod +x deploy.sh
./deploy.sh
```

### Option 2: Using Kustomize

```bash
cd k8s
kubectl apply -k .
```

### Option 3: Manual Deployment

```bash
# Deploy namespace
kubectl apply -f namespace.yaml

# Wait for namespace to be ready
kubectl wait namespace/three-tier --for condition=ready --timeout=60s

# Deploy database components
kubectl apply -f database/ -n three-tier

# Wait for database to be ready
kubectl wait --for=condition=ready pod -l app=mongodb -n three-tier --timeout=300s

# Deploy backend components
kubectl apply -f backend/ -n three-tier

# Wait for backend to be ready
kubectl wait --for=condition=ready pod -l app=backend -n three-tier --timeout=300s

# Deploy frontend components
kubectl apply -f frontend/ -n three-tier

# Deploy ingress
kubectl apply -f ingress.yml -n three-tier
```

## Verification

After deployment, verify all components are running:

```bash
kubectl get pods -n three-tier
kubectl get services -n three-tier
kubectl get ingress -n three-tier
```

The ingress will provide an external URL that you can use to access your application.

## Services

- **Frontend**: Accessible via the ingress external URL
- **Backend**: Available internally at `backend-svc:3500`
- **Database**: Available internally at `mongodb-svc:27017`

## Scaling

You can scale the frontend and backend deployments as needed:

```bash
# Scale frontend
kubectl scale deployment frontend -n three-tier --replicas=3

# Scale backend
kubectl scale deployment backend -n three-tier --replicas=2
```

## Cleanup

To delete the entire deployment:

```bash
kubectl delete -k .
# OR manually delete each component
kubectl delete namespace three-tier
```

If you created an EKS cluster specifically for this project, don't forget to delete it:

```bash
eksctl delete cluster --name <your-cluster-name> --region <your-region>
```

## Troubleshooting

1. **Check Pod Status**:
   ```bash
   kubectl get pods -n three-tier
   kubectl describe pod <pod-name> -n three-tier
   ```

2. **Check Logs**:
   ```bash
   kubectl logs -l app=frontend -n three-tier
   kubectl logs -l app=backend -n three-tier
   kubectl logs -l app=mongodb -n three-tier
   ```

3. **Check Ingress**:
   ```bash
   kubectl get ingress -n three-tier
   kubectl describe ingress three-tier-ingress -n three-tier
   ```

## Security Considerations

- Secrets for the database are stored in the `database/secrets.yaml` file
- For production use, consider using AWS Secrets Manager or HashiCorp Vault
- The MongoDB instance is configured with username/password authentication

## Environment Variables

The applications use the following environment variables:

**Backend**:
- `MONGO_CONN_STR`: MongoDB connection string
- `PORT`: Port number for the API server (default: 3500)

**Frontend**:
- `REACT_APP_API_URL`: URL for the backend API

## Customization

To customize the deployment for your specific needs:

1. Update image names in deployment files
2. Modify resource requests and limits
3. Adjust replica counts for scaling
4. Change storage class in PVC if needed
5. Update ingress configuration if using custom domains