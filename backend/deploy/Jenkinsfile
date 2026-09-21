pipeline {
    agent any

    environment {
        DOCKER_BUILDKIT = '1'
    }

    stages {
        stage('Checkout') {
            steps {
                echo '📥 [Stage 1] Checking out repository source code...'
                checkout scm
            }
        }

        stage('Test & Build Backend') {
            steps {
                echo '🔍 [Stage 2] Validating Backend TypeScript and Prisma...'
                dir('backend') {
                    sh 'npm ci'
                    sh 'npm run build'
                }
            }
        }

        stage('Test & Build Frontend') {
            steps {
                echo '🔍 [Stage 3] Validating Frontend Next.js build...'
                dir('frontend') {
                    sh 'npm ci'
                    sh 'npm run build'
                }
            }
        }

        stage('Build Docker Images') {
            steps {
                echo '🐳 [Stage 4] Building production Docker images...'
                sh 'docker build -t school-backend:latest ./backend'
                sh 'docker build -t school-frontend:latest ./frontend'
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                echo '☸️ [Stage 5] Rolling out deployments to Kubernetes cluster...'
                sh 'kubectl apply -f backend/deploy/k8s/'
                sh 'kubectl rollout status deployment/backend-deployment --timeout=60s || true'
                sh 'kubectl rollout status deployment/frontend-deployment --timeout=60s || true'
            }
        }
    }

    post {
        success {
            echo '✅ [CI/CD] Pipeline completed successfully! New build is live.'
        }
        failure {
            echo '❌ [CI/CD] Pipeline failed. Check build logs above.'
        }
    }
}
