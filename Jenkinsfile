pipeline {
  agent any
  environment {
    AWS_REGION = "us-east-1"
    ECR_REPO = "ecr-repo" 
    IMAGE_TAG = "${env.BUILD_NUMBER}"
    CLUSTER = "task-cluster"
    SERVICE = "task-service"
    TASK_FAMILY = "task-def"
  }
  stages {
    stage('Checkout') {
      steps {
        checkout scm
      }
    }
    stage('Install & Test') {
      steps {
        sh 'npm ci'
        sh '''
          if [ -f package.json ] && grep -q "\"test\"" package.json; then
            npm test || true
          else
            echo "No tests defined"
          fi
        '''
      }
    }
    stage('Docker: Build') {
      steps {
        sh "docker --version || true"
        sh "docker build -t ${ECR_REPO}:${IMAGE_TAG} ."
      }
    }
    stage('AWS ECR Login & Push') {
      steps {
        withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-creds']]) {
          sh '''
            aws --version
            aws configure set region ${AWS_REGION}
            ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
            ECR_URI="${ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO}"
            aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com
            docker tag ${ECR_REPO}:${IMAGE_TAG} ${ECR_URI}:${IMAGE_TAG}
            docker push ${ECR_URI}:${IMAGE_TAG}
            echo "IMAGE_URI=${ECR_URI}:${IMAGE_TAG}" > image_uri.txt
          '''
        }
      }
      archiveArtifacts artifacts: 'image_uri.txt', onlyIfSuccessful: true
    }
    stage('Deploy: Register Task Definition & Update Service') {
      steps {
        withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-creds']]) {
          sh '''
            ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
            ECR_URI="${ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO}"
            IMAGE="$(cat image_uri.txt | cut -d'=' -f2)"
            
            # prepare container definitions (replace image placeholder into template)
            cat taskdef.json.template | sed "s|__IMAGE__|${IMAGE}|g" > taskdef.json

            # register new task definition
            aws ecs register-task-definition \
              --region ${AWS_REGION} \
              --cli-input-json file://taskdef.json > register-output.json

            # get revision
            TD_ARN=$(jq -r '.taskDefinition.taskDefinitionArn' register-output.json)
            echo "Registered task definition: ${TD_ARN}"

            # update service to use latest task definition (force new deployment)
            aws ecs update-service \
              --region ${AWS_REGION} \
              --cluster ${CLUSTER} \
              --service ${SERVICE} \
              --task-definition ${TD_ARN} \
              --force-new-deployment

            # show status
            aws ecs describe-services --cluster ${CLUSTER} --services ${SERVICE} --region ${AWS_REGION} | jq '.services[0].deployments'
          '''
        }
      }
    }
  } // stages
  post {
    success {
      echo "Pipeline completed successfully. Visit the ALB/PUBLIC URL to verify."
    }
    failure {
      echo "Pipeline failed - check console output."
    }
  }
}
