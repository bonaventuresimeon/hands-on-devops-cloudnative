# 📦Case Study 1- Build Your APP (Student tracker App)

This FastAPI app allows students to register, track their weekly progress in the bootcamp, and view others' progress (using a shared MongoDB Atlas backend).

## 🚀 Goal (This Week)
> Dockerize this app, run it locally in a container, and push your image to DockerHub. You should be able to:
- Run the app inside Docker
- Test the API on your browser
- Share the image on DockerHub

---

## ✅ Prerequisites

Ensure the following are already installed in your VM (from [1.0 - Set Up Your Environment](https://github.com/ChisomJude/Hands-on-Devops-CloudNative/tree/master/1.0%20Setup%20your%20Enviroment)):

- Docker  
- Git  
- Python 3 & Pip  
- Kubernetes tools (kubectl, kind)  
  

---

## 🧪 Step-by-Step Guide

### 1. Clone the Project

```bash
git clone https://github.com/ChisomJude/student-project-tracker.git
cd student-project-tracker
```

### 2. Ensure you can connect to the vault Server
export VAULT_ADDR and VAULT_TOKEN

```
export VAULT_ADDR=http://<vaultip>:8200
export VAULT_TOKEN=<token will be provided in class chat room>

curl http://<vaultip>:8200/v1/sys/health
```

***We are using a central db, vault token and IP  will be provided in the Class Group, if you aren't part of the class you can create yours***


### 3. Run Locally 
To test the app locally before Dockerizing:

```bash
sudo apt update
sudo apt install python3-venv -y

python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload

#Go to: http://<your-VM-public-IP>:8000/docs, ensure Port 8000 is open in the network security group, and confirm this works
```


### 4. Build your image
A Dockerfile is already provided in the project repo; however, feel free to modify it to suit your needs.

✅ Build the image 
<br>✅ and run it locally<br>
✅ Push to to your dockerhub 

***Not familiar with docker? Check out this free course at kodekloud - https://learn.kodekloud.com/user/courses/docker-training-course-for-the-absolute-beginner***

```bash
docker build -t yourdockerhubusername/student-tracker:latest .
docker run -d -p 8000:8000 --env-file .env yourdockerhubusername/student-tracker:latest
# Check the app on your broswer or curl http://<your-vm-ip>:8000/docs
```
#### Push to DockerHub

```bash
docker login
docker push yourdockerhubusername/student-tracker: latest
```






