pipeline {
  agent any
  tools {
        maven 'maven' // Specify the version of Maven you want to use
  }
  stages {
      stage('Build Artifact') {
            steps {
              sh "mvn clean package -DskipTests=true"
              archive 'target/*.jar' //so that they can be downloaded later
            }
        }   
    }
}
