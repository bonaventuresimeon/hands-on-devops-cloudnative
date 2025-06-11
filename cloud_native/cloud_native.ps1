
# PowerShell Version of Cloud Native Setup (Simplified)
Write-Output "🚀 Starting Cloud Native Setup (Windows/WSL Compatible)"

# Check Docker
docker --version
if ($LASTEXITCODE -ne 0) {
    Write-Output "Please install Docker Desktop for Windows."
    exit 1
}

# Clone the student tracker repo
git clone https://github.com/ChisomJude/student-project-tracker.git
cd student-project-tracker

# Build Docker image
docker build -t bonaventure2025/student-tracker:latest .

# Run locally
docker run -d -p 8000:8000 --env-file .env bonaventure2025/student-tracker:latest

# Push to DockerHub
docker login -u bonaventure2025 --password yourdockerhubpassword
docker push bonaventure2025/student-tracker:latest

Write-Output "✅ Setup Complete. Visit http://localhost:8000/docs"
