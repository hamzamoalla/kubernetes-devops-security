pipeline {
    agent any
    tools {
        maven 'maven' // Specify the version of Maven you want to use
    }
    environment {
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

        stage('Deploy to Kubernetes') {
            steps {
                script {
                    // Use the secret file stored in Jenkins for the kubeconfig
                    withCredentials([file(credentialsId: 'kubeconfig-cred', variable: 'KUBECONFIG')]) {
                        sh '''
                            export KUBECONFIG=${KUBECONFIG}
                            kubectl config current-context
                            sed -i "s|image: ${IMAGE_NAME}:.*|image: ${IMAGE_NAME}:${IMAGE_TAG}|g" k8s_deployment_service.yaml
                            kubectl apply -f k8s_deployment_service.yaml --validate=false
                        '''
                    }
                }
            }
        }
    }
}
