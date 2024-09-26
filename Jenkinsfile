pipeline {
    agent any
    tools {
        maven 'maven' // Specify the version of Maven you want to use
    }
    environment {
        deploymentName = "devsecops"
        containerName = "devsecops-container"
        serviceName = "devsecops-svc"
        applicationURI="/increment/99"
        applicationURL="http://192.168.49.2"
        DOCKER_HUB_CREDENTIALS = credentials('docker_hub_repo')
        IMAGE_NAME = "hamzamoalla/my_repo"
        IMAGE_TAG = "devsecops-${env.BUILD_NUMBER}" // Use the Jenkins build number as the version
    }

    stages {
        stage('Build Artifact') {
            steps {
                sh "mvn clean package -DskipTests=true"
                archive 'target/*.jar' // so that they can be downloaded later
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

         stage('Mutation Tests - PIT') {
            steps {
                sh "mvn org.pitest:pitest-maven:mutationCoverage"
            }
            post {
                always {
                    pitmutation mutationStatsFile: 'target/pit-reports/**/mutations.xml'
                }
            }
        }

        
        stage('sonar') {
            steps {
                 sh "mvn clean verify sonar:sonar -Dsonar.projectKey=numeric-application -Dsonar.projectName='numeric-application' -Dsonar.host.url=http://192.168.49.4:9000 -Dsonar.token=sqp_164ad3e63f80d14d4c64b865c32cfd9db7866945"
            }
        }

        
        stage('Vulnerability Scan - Docker') {
            steps {
                parallel(
                    "Dependency Scan": {
                        sh "mvn dependency-check:check"
                    },
                    "Trivy Scan": {
                        sh "bash trivy-docker-image-scan.sh"
                    }
                )
            }
        }
        stage('Build and Push Image') {
            steps {
                script {
                    // Build the Docker image
                    sh "docker build -t ${IMAGE_NAME}:${IMAGE_TAG} ."
        
                    // Log in to Docker Hub and push the image
                    withCredentials([usernamePassword(credentialsId: 'docker_hub_repo', passwordVariable: 'DOCKER_HUB_PASSWORD', usernameVariable: 'DOCKER_HUB_USERNAME')]) {
                        sh "echo $DOCKER_HUB_PASSWORD | docker login -u $DOCKER_HUB_USERNAME --password-stdin"
                        sh "docker push ${IMAGE_NAME}:${IMAGE_TAG}"
                    }
                }
            }
        }


        
        stage('Vulnerability Scan - k8s') {
            steps {
                parallel(
                    "Kubesec Scan": {
                        sh "bash kubesec-scan.sh"
                    },
                    "Trivy Scan": {
                        sh "bash trivy-k8s-scan.sh"
                    }
                )
            }
        }
        stage('K8S Deployment - DEV') {
          steps {
            parallel(
              "Deployment": {
                withCredentials([file(credentialsId: 'kubeconfig-cred', variable: 'KUBECONFIG')]) {
                    sh '''
                        export KUBECONFIG=${KUBECONFIG}
                        bash k8s-deployment.sh
                    '''
                }
              },
              "Rollout Status": {
                withCredentials([file(credentialsId: 'kubeconfig-cred', variable: 'KUBECONFIG')]) {
                    sh '''
                        export KUBECONFIG=${KUBECONFIG}
                        bash k8s-deployment-rollout-status.sh
                    '''
                }
              }
            )
          }
        }
        
        stage('Integration Tests - DEV') {
          steps {
            script {
              try {
                withCredentials([file(credentialsId: 'kubeconfig-cred', variable: 'KUBECONFIG')]) {
                    sh '''
                        export KUBECONFIG=${KUBECONFIG}
                        bash integration-test.sh
                    '''
                }
              } catch (e) {
                withCredentials([file(credentialsId: 'kubeconfig-cred', variable: 'KUBECONFIG')]) {
                    sh '''
                        export KUBECONFIG=${KUBECONFIG}
                        kubectl -n default rollout undo deploy ${deploymentName}
                    '''
                }
                throw e
              }
            }
          }
        }

       stage('OWASP ZAP - DAST') {
          steps {
            withCredentials([file(credentialsId: 'kubeconfig-cred', variable: 'KUBECONFIG')]) {
                sh '''
                export KUBECONFIG=${KUBECONFIG}
                bash zap.sh
                '''
            }
          }
        }
        stage('K8S Deployment - PROD') {
          steps {
            parallel(
              "Deployment": {
                withCredentials([file(credentialsId: 'kubeconfig-cred', variable: 'KUBECONFIG')]) {
                    sh '''
                        export KUBECONFIG=${KUBECONFIG}
                        sed -i "s|image: hamzamoalla/my_repo:devsecops-.*|image: ${IMAGE_NAME}:${IMAGE_TAG}|" k8s_PROD-deployment_service.yaml
                    '''
                  sh "kubectl -n prod apply -f k8s_PROD-deployment_service.yaml"
                }
              },
              "Rollout Status": {
                withCredentials([file(credentialsId: 'kubeconfig-cred', variable: 'KUBECONFIG')]) {
                    sh '''
                        export KUBECONFIG=${KUBECONFIG}
                    '''
                    sh "bash k8s-PROD-deployment-rollout-status.sh"
                }
              }
            )
          }
        }
    
        stage('Integration Tests - PROD') {
          steps {
            script {
              try {
                withCredentials([file(credentialsId: 'kubeconfig-cred', variable: 'KUBECONFIG')]) {
                    sh '''
                        export KUBECONFIG=${KUBECONFIG}
                    '''
                  sh "bash integration-test-PROD.sh"
                }
              } catch (e) {
                withCredentials([file(credentialsId: 'kubeconfig-cred', variable: 'KUBECONFIG')]) {
                    sh '''
                        export KUBECONFIG=${KUBECONFIG}
                    '''
                    sh "kubectl -n prod rollout undo deploy ${deploymentName}"
                }
                throw e
              }
            }
          }
        }   
        
        // stage('Deploy to Kubernetes') {
        //     steps {
        //         script {
        //             // Use the secret file stored in Jenkins for the kubeconfig
        //             withCredentials([file(credentialsId: 'kubeconfig-cred', variable: 'KUBECONFIG')]) {
        //                 sh '''
        //                     export KUBECONFIG=${KUBECONFIG}
        //                     kubectl config current-context
        //                     sed -i "s|image: ${IMAGE_NAME}:.*|image: ${IMAGE_NAME}:${IMAGE_TAG}|g" k8s_deployment_service.yaml
        //                     kubectl apply -f k8s_deployment_service.yaml --validate=false
        //                 '''
        //             }
        //         }
        //     }
        // }
    }
}
