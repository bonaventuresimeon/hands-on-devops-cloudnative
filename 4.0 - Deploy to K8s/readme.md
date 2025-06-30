# Deploy Your to Kubernetes 
In this Phase we will work on k8s app deployment and  Ingress. We deploy your app as deployment and expose externally

- Deploy an app from Docker Hub
- Expose it using Ingress + NGINX
- Access it in browser


### Prerequisite
- Your Cluster is ready and was created using Port mapping, ie ensure your cluster `kind-config.yaml` looks like this.Including container port mapping . Ensure to add these ports on your security group

```yml
# kind-ingress.yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
  - role: control-plane
    extraPortMappings:
      - containerPort: 80   # For Ingress HTTP
        hostPort: 80
      - containerPort: 443  # For Ingress HTTPS (optional)
        hostPort: 443
  - role: worker
```

Otherwise recreate using this config and command below. First Delete the old cluster and create a `kind-config.yaml` file as shown

```
kind delete cluster --name <your-clustername>

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

### Create  a Secret

```
# create a file vault-secret.yaml

apiVersion: v1
kind: Secret
metadata:
  name: vault-env-secret
type: Opaque
stringData:
  VAULT_ADDR: "http://44.204.193.107:8200"
  VAULT_ROLE_ID: "f7af58b1-5c22-7c2d-c659-0425d9ce94b2"
  VAULT_SECRET_ID: "d5f736da-785b-8f5c-9258-48d5d7c43c06"
```

### Deploy your APP

Create a Deployment file - `student-tracker.yaml`. This contains your deployment and your service

```yml

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
          env:
            - name: VAULT_ADDR
              valueFrom:
                secretKeyRef:
                  name: vault-env-secret
                  key: VAULT_ADDR
            - name: VAULT_ROLE_ID
              valueFrom:
                secretKeyRef:
                  name: vault-env-secret
                  key: VAULT_ROLE_ID
            - name: VAULT_SECRET_ID
              valueFrom:
                secretKeyRef:
                  name: vault-env-secret
                  key: VAULT_SECRET_ID

```

Apply the file using kubectl create -f <filename.yml>



### Create a Service 

```yml
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

### Create ingress Resource
create the file  `student-tracker-ingress.yaml`

```yml
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
