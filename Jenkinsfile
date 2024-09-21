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

      stage('Deploy to kubernetes') {
          steps {
              script {
                  // Using the secret file stored in Jenkins for the kubeconfig
                  withCredentials([file(credentialsId: 'kubeconfig-cred', variable: 'KUBECONFIG')]) {
                      sh '''
                        
                        export KUBECONFIG=${KUBECONFIG}
                        kubectl config current-context
                        kubectl apply -f k8s_deployment_service.yaml --validate=false
                      '''
                  }
              }
          }
      }
    }
}
