pipeline {
    agent any

    environment {
        // Define environment variables if needed
        NODE_VERSION = '18'
    }

    stages {
        stage('Checkout') {
            steps {
                echo 'Checking out code from GitHub...'
                checkout scm
            }
        }

        stage('Setup Environment') {
            steps {
                echo 'Setting up build environment...'
                // For Node.js applications
                sh '''
                    node --version
                    npm --version
                '''
            }
        }

        stage('Install Dependencies') {
            steps {
                echo 'Installing dependencies...'
                sh 'npm install'
            }
        }

        stage('Build') {
            steps {
                echo 'Building the application...'
                sh 'npm run build'
            }
        }

        stage('Test') {
            steps {
                echo 'Running tests...'
                sh 'npm test'
            }
            post {
                always {
                    // Publish test results if available
                    publishTestResults testResultsPattern: 'test-results.xml'
                }
            }
        }

        stage('Deploy') {
            when {
                branch 'main'
            }
            steps {
                echo 'Deploying application...'
                // Add your deployment commands here
                sh '''
                    echo "Deploying to staging/production..."
                    # Add actual deployment commands
                '''
            }
        }
    }

    post {
        success {
            echo 'Pipeline succeeded!'
            // Send success notification
            emailext (
                subject: "✅ Build Success: ${env.JOB_NAME} - ${env.BUILD_NUMBER}",
                body: """
                    <h2>Build Successful!</h2>
                    <p><strong>Job:</strong> ${env.JOB_NAME}</p>
                    <p><strong>Build Number:</strong> ${env.BUILD_NUMBER}</p>
                    <p><strong>Build URL:</strong> <a href="${env.BUILD_URL}">${env.BUILD_URL}</a></p>
                """,
                to: 'your-email@college.edu',
                mimeType: 'text/html'
            )
        }
        failure {
            echo 'Pipeline failed!'
            // Send failure notification
            emailext (
                subject: "❌ Build Failed: ${env.JOB_NAME} - ${env.BUILD_NUMBER}",
                body: """
                    <h2>Build Failed!</h2>
                    <p><strong>Job:</strong> ${env.JOB_NAME}</p>
                    <p><strong>Build Number:</strong> ${env.BUILD_NUMBER}</p>
                    <p><strong>Build URL:</strong> <a href="${env.BUILD_URL}">${env.BUILD_URL}</a></p>
                    <p>Please check the build logs for more details.</p>
                """,
                to: 'your-email@college.edu',
                mimeType: 'text/html'
            )
        }
        always {
            echo 'Cleaning up workspace...'
            cleanWs()
        }
    }
}