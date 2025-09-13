DevOps Task – CI/CD on AWS ECS with Jenkins
📌 Overview

This project demonstrates a complete CI/CD pipeline for deploying a containerized Node.js application to AWS ECS (Fargate) using Jenkins, Docker, Terraform, and ECR.

The pipeline:

1. Builds a Docker image of the Node.js app.

2. Pushes the image to Amazon ECR (with both immutable build tag and latest).

3. Registers a new ECS task definition.

4. Updates the ECS service to run the new task.

5. Sends logs to CloudWatch for observability.


🛠️ Tools & Services Used

Application: Node.js + Express

Containerization: Docker

CI/CD: Jenkins (pipeline as code – Jenkinsfile)

Cloud Provider: AWS

Amazon ECR (image registry)

Amazon ECS (Fargate launch type)

Application Load Balancer (public ingress)

CloudWatch Logs (logging)

Infrastructure as Code: Terraform

🚀 Setup & Deployment Guide
1. Prerequisites

AWS Account with IAM permissions for ECS, ECR, VPC, CloudWatch.

Jenkins server (running on EC2/VM/Container).

Installed locally (if testing without Jenkins):

Docker

AWS CLI (aws configure)

Terraform

Node.js

2. Clone the repository
git clone <your-repo-url>
cd your-repo

3. Run application locally (optional)
```
cd app
npm install
npm start
# App runs on http://localhost:3000
# Health check endpoint: http://localhost:3000/health
```

4. Build & Push Docker Image to ECR

Authenticate with ECR:
```
aws ecr get-login-password --region us-east-1 \
  | docker login --username AWS --password-stdin <AWS_ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com
```

Build and tag the image:
```
docker build -t devops-task-ecr:3 .
docker tag devops-task-ecr:3 <AWS_ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com/devops-task-ecr:3
```

Push to ECR:
```
docker push <AWS_ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com/devops-task-ecr:3
```

5. Provision Infrastructure with Terraform ( Run locally on local 
```
cd infra
terraform init
terraform apply -auto-approve
```

Terraform will create:

ECS Cluster

Task Definition & Service

ALB + Target Group + Listener

Security Groups

CloudWatch Log Group

6. Jenkins CI/CD Pipeline

Add your GitHub repo to Jenkins (multibranch or pipeline job).

Jenkinsfile pipeline stages:

Checkout – pull code from GitHub

Install & Test – install Node dependencies & run tests

Docker Build – build app image

ECR Push – push image to AWS ECR

Terraform Apply – apply infra changes

Deploy to ECS – update ECS service with new task definition

Trigger: on push to main branch.

7. Access the Application

Once deployed, the application is accessible via the ALB DNS name:
```
curl http://<ALB-DNS-NAME>/health
```

Or open in browser:
```
👉 http://<ALB-DNS-NAME>
```
8. Logs & Monitoring

Logs available in CloudWatch under:

/ecs/devops-task


ECS Task logs stream app output.

📊 Deployment Proof

Inside deployment-proof/
:

public_url.txt → contains ALB DNS name.

screenshots/ → Webpage, Jenkins pipeline, ECS console, logs.



📐 Architecture Diagram

Flow:

<img src="https://github.com/abhinavellath/devops-task/blob/main/assets/architecture.png" alt="Banner" />

✍️ Author

Name: Abhinav Ellath

Assignment: DevOps Engineer Task
