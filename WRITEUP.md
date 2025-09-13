## 🔧 Tools & Services Used

1. AWS ECS (Fargate) → For container orchestration & serverless compute.

2. Amazon ECR → To store Docker container images.

3. AWS CloudWatch → For centralized logging & monitoring.

4. Jenkins → CI/CD pipeline automation.

5. Docker → Containerization of the application.

6. Terraform / CloudFormation (if used) → Infrastructure as Code for provisioning.

7. GitHub → Version control & project repository.

## 🚧 Challenges Faced & Solutions

 **ECR Image Pull Failure (latest: not found)**

Cause: The task definition was pointing to the latest tag, but only versioned tags (e.g., :3) existed in ECR.

Solution: Updated ECS task definition to use the correct image tag pushed by Jenkins.

**CloudWatch Log Group Not Found**

Cause: ECS task tried to write logs to a non-existing log group.

Solution: Created the log group (/ecs/devops-task) manually via AWS CLI/Terraform before running ECS tasks.

**Jenkins Agent Missing AWS CLI**

Cause: Jenkins build step failed (aws: not found).

Solution: Installed AWS CLI on Jenkins agent using package manager (apt-get install awscli -y) or added it to the Docker image for the Jenkins agent.

**Networking Issues in Fargate**

Cause: Tasks couldn’t pull images or connect to the internet.

Solution: Ensured ECS task was launched in a VPC with proper subnets, route tables, and an attached Internet Gateway / NAT Gateway.

## 💡 Possible Improvements

1. Blue-Green / Rolling Deployments → Safer ECS updates without downtime.

2. Monitoring Enhancements → Use Prometheus + Grafana along with CloudWatch for better observability.

3. Secrets Management → Store sensitive configs in AWS Secrets Manager instead of hardcoding.

4. Cost Optimization → Automate resource cleanup, use smaller Fargate task sizes, and enable CloudWatch log retention policies.

5. Automated Infrastructure Provisioning → Migrate all manual steps (log group creation, repo setup) fully into Terraform/CloudFormation.
