pipeline {
  agent any
  tools {
        maven 'maven' // Specify the version of Maven you want to use
  }
  environment {
        DOCKER_HUB_CREDENTIALS = credentials('docker_hub_repo')
        IMAGE_NAME = "hamzamoalla/my_repo"
        IMAGE_TAG = "devsecops-${env.BUILD_NUMBER}"  // Utilisation du numéro de build Jenkins comme version
  }
  stages {
      stage('Build Artifact') {
            steps {
              sh "mvn clean package -DskipTests=true"
              archive 'target/*.jar' //so that they can be downloaded later
            }
        }
      
      stage('Unit Tests - JUnit and Jacoco') {
            steps { 
              sh "mvn test"
            }
            post {
              always {
                junit 'target/surefire-reports/*.xml' 
                jacoco execPattern: 'target/jacoco.exec'
              }
            }
      }

      stage('Build Variable Image') {
            steps {
                script {
                    sh "docker build -t ${IMAGE_NAME}:${IMAGE_TAG} ."
                }
            }
        }
      stage('Push Images to Docker Hub') {
            steps {
                script {
                    withCredentials([usernamePassword(credentialsId: 'docker_hub_repo', passwordVariable: 'DOCKER_HUB_PASSWORD', usernameVariable: 'DOCKER_HUB_USERNAME')]) {
                        sh "echo $DOCKER_HUB_PASSWORD | docker login -u $DOCKER_HUB_USERNAME --password-stdin"
                        sh "docker push ${IMAGE_NAME}:${IMAGE_TAG}"
                    }
                }
            }
        }

      stage('Deploy to kubernetes') {
          steps {
              script {
                  // Using the secret file stored in Jenkins for the kubeconfig
                  withCredentials([file(credentialsId: 'kubeconfig-minikube.txt', variable: 'KUBECONFIG')]) {
                      sh '''
                        
                        export KUBECONFIG=${KUBECONFIG}
                        kubectl config current-context
                        kubectl apply -f k8s_deployment_service.yaml
                      '''
                  }
              }
          }
      }
    }
}
