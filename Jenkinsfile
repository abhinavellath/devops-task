pipeline {
  agent any
  environment {
    AWS_REGION = "us-east-1"
    ECR_REPO = "ecr-repo" 
    IMAGE_TAG = "${env.BUILD_NUMBER}"
    CLUSTER = "devops-task-cluster"   
    SERVICE = "devops-task-service" 
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
    stage('Load Terraform Outputs') {
      steps {
        sh '''
          if [ ! -f infra/terraform-outputs.json ]; then
            echo "ERROR: infra/terraform-outputs.json not found"
            exit 1
          fi

          EXEC_ROLE_ARN=$(jq -r .exec_role_arn.value infra/terraform-outputs.json)
          TASK_ROLE_ARN=$(jq -r .task_role_arn.value infra/terraform-outputs.json || echo $EXEC_ROLE_ARN)
          CLUSTER=$(jq -r .ecs_cluster.value infra/terraform-outputs.json)
          SERVICE=$(jq -r .ecs_service.value infra/terraform-outputs.json)

          echo "EXEC_ROLE_ARN=$EXEC_ROLE_ARN" > tf.env
          echo "TASK_ROLE_ARN=$TASK_ROLE_ARN" >> tf.env
          echo "CLUSTER=$CLUSTER" >> tf.env
          echo "SERVICE=$SERVICE" >> tf.env
        '''
        script {
          def tf = readFile('tf.env').split("\n").collectEntries { line ->
            def (k,v) = line.split('=')
            [(k): v]
          }
          env.EXEC_ROLE_ARN = tf['EXEC_ROLE_ARN']
          env.TASK_ROLE_ARN = tf['TASK_ROLE_ARN']
          env.CLUSTER = tf['CLUSTER']
          env.SERVICE = tf['SERVICE']
        }
      }
    }
    stage('Deploy: Register Task Definition & Update Service') {
      steps {
        withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-creds']]) {
          sh '''
            IMAGE=$(cat image_uri.txt | cut -d'=' -f2)

            # prepare task definition from template (replace all placeholders)
            sed -e "s|__IMAGE__|${IMAGE}|g" \
                -e "s|__EXEC_ROLE_ARN__|${EXEC_ROLE_ARN}|g" \
                -e "s|__TASK_ROLE_ARN__|${TASK_ROLE_ARN}|g" \
                taskdef.json.template > taskdef.json

            # register new task definition
            aws ecs register-task-definition \
              --region ${AWS_REGION} \
              --cli-input-json file://taskdef.json > register-output.json

            # get task definition ARN
            TD_ARN=$(jq -r '.taskDefinition.taskDefinitionArn' register-output.json)
            echo "Registered task definition: ${TD_ARN}"

            # update ECS service with new task definition
            aws ecs update-service \
              --region ${AWS_REGION} \
              --cluster ${CLUSTER} \
              --service ${SERVICE} \
              --task-definition ${TD_ARN} \
              --force-new-deployment

            # show deployment status
            aws ecs describe-services \
              --region ${AWS_REGION} \
              --cluster ${CLUSTER} \
              --services ${SERVICE} | jq '.services[0].deployments'
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
