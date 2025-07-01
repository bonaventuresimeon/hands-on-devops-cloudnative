# Deploy Your to Kubernetes 
In this Phase we will work on k8s app deployment and  Ingress. We deploy your app as a deployment and expose it externally

- Deploy an app from Docker Hub
- Expose it using Ingress + NGINX INGRESS CONTROLLER
- Access it in browser


### Prerequisite
- Your Cluster is ready and was created using Port mapping, ie ensure your cluster `kind-config.yaml` looks like this. Including container port mapping. Ensure to add these ports to your security group as well. Delete and recreate Week 3 Clusterif necessary. `kind delete cluster --name <your-clustername>`

```yml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane  # First node (control plane + worker)
  kubeadmConfigPatches:
  - |
    kind: InitConfiguration
    nodeRegistration:
      kubeletExtraArgs:
        node-labels: "ingress-ready=true"
  extraPortMappings:
  - containerPort: 80
    hostPort: 80
    protocol: TCP
  - containerPort: 443
    hostPort: 443
    protocol: TCP
- role: worker  # Second node (worker only)
```

Then run these to create the cluster and Nginx controller

```yml
#create your cluster
kind create cluster --name my-cluster --config kind-config.yaml

```


### Set Up Ingress Controller for Kind

```yml
# create ingress-controller
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml

# Patch the ingress service to use host ports:
kubectl patch svc ingress-nginx-controller -n ingress-nginx \
  --type='merge' \
  -p '{"spec":{"type":"LoadBalancer"}}'

```

### Create  a Secret

```
# create a file vault-secret.yaml

apiVersion: v1
kind: Secret
metadata:
  name: vault-secrets
  namespace: my-app
type: Opaque
stringData:
  VAULT_ADDR: "http://44.204.193.107:8200"
  VAULT_ROLE_ID: "add as provided in chatroom"
  VAULT_SECRET_ID: "add as provided in chatroom"
```

### Deploy your APP

Create a Deployment file - `student-tracker.yaml`. This contains your deployment and your service. I created mine in  a namespace- my-app. You can choose to create a namespace or remove this from all your manifest

```yml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
  namespace: my-app
  labels:
    app: my-app
spec:
  replicas: 2
  selector:
    matchLabels:
      app: my-app
  template:
    metadata:
      labels:
        app: my-app
    spec:
      containers:
      - name: my-app
        image: chisomjude/student-tracker:latest  #use your own image
        ports:
        - containerPort: 8000
        env:
        - name: VAULT_ADDR
          valueFrom:
            secretKeyRef:
              name: vault-secrets
              key: VAULT_ADDR
        - name: VAULT_SECRET_ID
          valueFrom:
            secretKeyRef:
              name: vault-secrets
              key: VAULT_SECRET_ID
        - name: VAULT_ROLE_ID
          valueFrom:
            secretKeyRef:
              name: vault-secrets
              key: VAULT_ROLE_ID
        resources:
          requests:
            cpu: "100m"
            memory: "128Mi"
          limits:
            cpu: "500m"
            memory: "512Mi"

```

Apply the file using `kubectl create -f <filename.yml>`



### Create a Service 

```yml
apiVersion: v1
kind: Service
metadata:
  name: my-app-service
  namespace: my-app
spec:
  selector:
    app: my-app
  ports:
    - protocol: TCP
      port: 80
      targetPort: 8000

```

### Create ingress Resource
create the file  `student-tracker-ingress.yaml`

```yml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: my-app-ingress
  namespace: my-app
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  rules:
  - host: ec2-13-222-38-97.compute-1.amazonaws.com  # Replace with your EC2's public DNS 
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: my-app-service
            port:
              number: 80
```

Apply it using `kubectl apply -f student-tracker-ingress.yaml`


### Confirm all resource is created and running

![image](https://github.com/user-attachments/assets/191d257e-a325-499b-9155-93dcf1f874c5)


### Usefull command to check your resource

```
kubectl get pods
kubectl get ingress
kubectl get service
kubectl get -n ingress-nginx deploy/ingress-nginx-controller
kubectl logs -n ingress-nginx deploy/ingress-nginx-controller

```

### Confirm your app is accessible over the internet

![image](https://github.com/user-attachments/assets/f4a9ebf1-9341-47b2-b883-0e6533514de3)

**Yes! Week 4 is Done and Dusted. You scaled through deployment with k8s. Star this Repo, Let Move on to Week 5**

