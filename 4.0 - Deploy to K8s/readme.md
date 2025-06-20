# Deploy Your to Kubernetes 
In this Phase we will work on k8s Ingress Features

- Deploy an app from Docker Hub
- Expose it using Ingress + NGINX
- Access it in browser


### Prerequisite
- Your Clustomer was created using Port mapping, ie ensure your cluster kind-config.yaml looks like this
```
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
  - role: control-plane
    extraPortMappings:
      - containerPort: 80
        hostPort: 80
        protocol: TCP
      - containerPort: 443
        hostPort: 443
        protocol: TCP
  - role: worker

```
otherwise recreate using this config and command below

```
kind create cluster --name student-cluster --config kind-config.yaml --image kindest/node:v1.30.0

```

### Set Up Ingress Controller for Kind

```
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.10.1/deploy/static/provider/kind/deploy.yaml

kubectl wait --namespace ingress-nginx \
  --for=condition=Ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=90s

```

### Deploy your APP

Create a Deployment file - `student-tracker.yaml` This contains your deployment and your service

```
apiVersion: apps/v1
kind: Deployment
metadata:
  name: student-tracker-app
spec:
  replicas: 1
  selector:
    matchLabels:
      app: student-tracker-app
  template:
    metadata:
      labels:
        app: student-tracker-app
    spec:
      containers:
        - name: student-tracker
          image: chisomjude/student-tracker
          ports:
            - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: student-tracker-service
spec:
  selector:
    app: student-tracker-app
  ports:
    - protocol: TCP
      port: 80
      targetPort: 80


```

Apply the file
```
kubectl apply -f student-tracker.yaml

```

### Create ingress Resource
create the file  `student-tracker-ingress.yaml`

```
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: student-tracker-ingress
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  rules:
    - http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: student-tracker-service
                port:
                  number: 80
```

Apply it using `kubectl apply -f student-tracker-ingress.yaml`

### Usefull command to check your resource

```
kubectl get pods
kubectl get ingress
kubectl logs -n ingress-nginx deploy/ingress-nginx-controller

```
