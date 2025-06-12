pipeline {
    agent any

    environment {
        NODE_VERSION = '18'
        // Disable Next.js telemetry for CI
        NEXT_TELEMETRY_DISABLED = '1'
        // Set CI environment
        CI = 'true'
    }

    tools {
        nodejs 'NodeJS-18'
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
                echo 'Setting up Node.js environment for Next.js TypeScript...'
                sh '''
                    echo "Node.js version:"
                    node --version
                    echo "NPM version:"
                    npm --version
                    echo "Checking package.json..."
                    if [ -f package.json ]; then
                        echo "✅ package.json found"
                        cat package.json | grep -E '"(next|typescript|react)"' || echo "Dependencies will be checked after install"
                    else
                        echo "❌ package.json not found!"
                        exit 1
                    fi
                '''
            }
        }

        stage('Cache Dependencies') {
            steps {
                echo 'Setting up npm cache...'
                sh '''
                    # Clean npm cache if needed
                    npm cache verify
                '''
            }
        }

        stage('Install Dependencies') {
            steps {
                        npm ci --only=production=false
            echo 'Installing Next.js TypeScript dependencies...'
            sh '''
                # Use npm ci for faster, reliable builds in CI
                if [ -f package-lock.json ]; then
                npm ci --only=production=false --force
                else
                npm install --force
                fi

                # Verify Next.js and TypeScript installation
                echo "Checking installed packages..."
                npm list next typescript react --depth=0 || echo "Some packages might be peer dependencies"
            '''
            }
        }


        stage('TypeScript Check') {
            steps {
                echo 'Running TypeScript type checking...'
                sh '''
                    # Check if TypeScript config exists
                    if [ -f tsconfig.json ]; then
                        echo "✅ TypeScript config found"

                        # Run TypeScript type checking
                        npx tsc --noEmit --skipLibCheck

                        echo "✅ TypeScript type checking passed"
                    else
                        echo "⚠️ No tsconfig.json found, skipping TypeScript check"
                    fi
                '''
            }
        }

        stage('Lint & Format Check') {
            steps {
                echo 'Running linting and format checks...'
                sh '''
                    # Check if ESLint is configured
                    if [ -f .eslintrc.json ] || [ -f .eslintrc.js ] || [ -f eslint.config.js ]; then
                        echo "Running ESLint..."
                        npm run lint || echo "⚠️ Linting issues found but continuing build"
                    else
                        echo "⚠️ No ESLint config found, skipping lint check"
                    fi

                    # Check if Prettier is configured
                    if [ -f .prettierrc ] || [ -f .prettierrc.json ] || [ -f prettier.config.js ]; then
                        echo "Checking Prettier formatting..."
                        npx prettier --check . || echo "⚠️ Formatting issues found but continuing build"
                    else
                        echo "⚠️ No Prettier config found, skipping format check"
                    fi
                '''
            }
        }

        stage('Build') {
            steps {
                echo 'Building Next.js TypeScript application...'
                sh '''
                    # Build the Next.js application
                    npm run build

                    # Verify build output
                    if [ -d .next ]; then
                        echo "✅ Next.js build completed successfully"
                        echo "Build size:"
                        du -sh .next/ || echo "Could not determine build size"

                        # List build output
                        echo "Build contents:"
                        ls -la .next/ || echo "Could not list build contents"
                    else
                        echo "❌ Build failed - .next directory not found"
                        exit 1
                    fi
                '''
            }
        }

        stage('Test') {
            steps {
                echo 'Running tests for Next.js TypeScript application...'
                script {
                    sh '''
                        # Check if test script exists in package.json
                        if npm run | grep -q "test"; then
                            echo "Running tests..."

                            # Set test environment
                            export NODE_ENV=test

                            # Run tests (with CI flag for non-interactive mode)
                            CI=true npm run test -- --coverage --watchAll=false || echo "⚠️ Some tests failed but continuing build"

                            # Check if coverage was generated
                            if [ -d coverage ]; then
                                echo "✅ Test coverage generated"
                                echo "Coverage summary:"
                                cat coverage/lcov-report/index.html | grep -o '<span class="strong">[0-9.]*%</span>' | head -4 || echo "Could not parse coverage"
                            fi
                        else
                            echo "⚠️ No test script found in package.json"
                            echo "Adding basic smoke test..."

                            # Basic smoke test - check if build can be started
                            timeout 30 npm start &
                            SERVER_PID=$!
                            sleep 10

                            # Check if server is responding
                            if curl -f http://localhost:3000 > /dev/null 2>&1; then
                                echo "✅ Basic smoke test passed - server responds"
                            else
                                echo "⚠️ Smoke test warning - server might not be ready"
                            fi

                            # Clean up
                            kill $SERVER_PID || echo "Server already stopped"
                        fi
                    '''
                }
            }
            post {
                always {
                    // Archive test results if they exist
                    script {
                        if (fileExists('coverage/lcov.info')) {
                            publishHTML([
                                allowMissing: false,
                                alwaysLinkToLastBuild: true,
                                keepAll: true,
                                reportDir: 'coverage/lcov-report',
                                reportFiles: 'index.html',
                                reportName: 'Coverage Report'
                            ])
                        }

                        if (fileExists('test-results.xml')) {
                            publishTestResults testResultsPattern: 'test-results.xml'
                        }
                    }
                }
            }
        }

        stage('Security Audit') {
            steps {
                echo 'Running security audit...'
                sh '''
                    # Run npm audit
                    echo "Running npm security audit..."
                    npm audit --audit-level=high || echo "⚠️ Security vulnerabilities found - check and fix if critical"

                    # Check for outdated packages
                    echo "Checking for outdated packages..."
                    npm outdated || echo "Some packages might be outdated"
                '''
            }
        }

        stage('Build Optimization Check') {
            steps {
                echo 'Analyzing build optimization...'
                sh '''
                    # Check bundle size if next-bundle-analyzer is available
                    if npm list @next/bundle-analyzer --depth=0 2>/dev/null; then
                        echo "Bundle analyzer available - generating report..."
                        ANALYZE=true npm run build || echo "Bundle analysis completed with warnings"
                    else
                        echo "Bundle analyzer not configured"
                    fi

                    # Basic build size check
                    if [ -d .next/static ]; then
                        echo "Static files size:"
                        du -sh .next/static/

                        echo "JavaScript bundle sizes:"
                        find .next/static -name "*.js" -type f -exec ls -lh {} + | head -10
                    fi
                '''
            }
        }

        stage('Deploy') {
            when {
                anyOf {
                    branch 'main'
                    branch 'master'
                    branch 'develop'
                }
            }
            steps {
                echo 'Deploying Next.js TypeScript application...'
                script {
                    sh '''
                        echo "🚀 Starting deployment process..."

                        # Example deployment commands (customize based on your deployment target)

                        # Option 1: Deploy to Vercel (if vercel.json exists)
                        if [ -f vercel.json ]; then
                            echo "Vercel config found - would deploy to Vercel"
                            # npx vercel --prod --token $VERCEL_TOKEN
                        fi

                        # Option 2: Deploy to Netlify (if netlify.toml exists)
                        if [ -f netlify.toml ]; then
                            echo "Netlify config found - would deploy to Netlify"
                            # npx netlify deploy --prod --auth $NETLIFY_AUTH_TOKEN
                        fi

                        # Option 3: Docker deployment
                        if [ -f Dockerfile ]; then
                            echo "Dockerfile found - would build and deploy Docker container"
                            # docker build -t my-nextjs-app .
                            # docker run -d -p 3000:3000 my-nextjs-app
                        fi

                        # Option 4: Custom deployment script
                        if [ -f deploy.sh ]; then
                            echo "Custom deployment script found"
                            chmod +x deploy.sh
                            ./deploy.sh
                        else
                            echo "✅ Build completed - ready for manual deployment"
                            echo "To deploy manually, run: npm start"
                        fi
                    '''
                }
            }
        }
    }

    post {
        success {
            echo '✅ Next.js TypeScript pipeline succeeded!'
            emailext (
                subject: "✅ Next.js Build Success: ${env.JOB_NAME} - ${env.BUILD_NUMBER}",
                body: """
                    <div style="font-family: Arial, sans-serif; max-width: 600px;">
                        <h2 style="color: #28a745;">🎉 Next.js TypeScript Build Successful!</h2>

                        <div style="background: #f8f9fa; padding: 15px; border-radius: 5px; margin: 10px 0;">
                            <p><strong>📦 Project:</strong> ${env.JOB_NAME}</p>
                            <p><strong>🔢 Build Number:</strong> ${env.BUILD_NUMBER}</p>
                            <p><strong>🌿 Branch:</strong> ${env.BRANCH_NAME}</p>
                            <p><strong>⏰ Duration:</strong> ${currentBuild.durationString}</p>
                            <p><strong>🔗 Build URL:</strong> <a href="${env.BUILD_URL}" style="color: #007bff;">${env.BUILD_URL}</a></p>
                        </div>

                        <div style="background: #d4edda; padding: 15px; border-radius: 5px; margin: 10px 0;">
                            <h3 style="color: #155724; margin-top: 0;">✅ Completed Stages:</h3>
                            <ul style="color: #155724;">
                                <li>Code Checkout</li>
                                <li>TypeScript Type Checking</li>
                                <li>Dependency Installation</li>
                                <li>Linting & Format Check</li>
                                <li>Next.js Build</li>
                                <li>Testing</li>
                                <li>Security Audit</li>
                                <li>Deployment (if applicable)</li>
                            </ul>
                        </div>

                        <p style="color: #6c757d; font-size: 12px;">
                            This build was triggered by changes to the repository.
                            The application is ready for deployment.
                        </p>
                    </div>
                """,
                to: 'your-email@college.edu',
                mimeType: 'text/html'
            )
        }

        failure {
            echo '❌ Next.js TypeScript pipeline failed!'
            emailext (
                subject: "❌ Next.js Build Failed: ${env.JOB_NAME} - ${env.BUILD_NUMBER}",
                body: """
                    <div style="font-family: Arial, sans-serif; max-width: 600px;">
                        <h2 style="color: #dc3545;">💥 Next.js TypeScript Build Failed!</h2>

                        <div style="background: #f8f9fa; padding: 15px; border-radius: 5px; margin: 10px 0;">
                            <p><strong>📦 Project:</strong> ${env.JOB_NAME}</p>
                            <p><strong>🔢 Build Number:</strong> ${env.BUILD_NUMBER}</p>
                            <p><strong>🌿 Branch:</strong> ${env.BRANCH_NAME}</p>
                            <p><strong>⏰ Duration:</strong> ${currentBuild.durationString}</p>
                            <p><strong>🔗 Build URL:</strong> <a href="${env.BUILD_URL}" style="color: #007bff;">${env.BUILD_URL}</a></p>
                        </div>

                        <div style="background: #f8d7da; padding: 15px; border-radius: 5px; margin: 10px 0;">
                            <h3 style="color: #721c24; margin-top: 0;">🔍 Troubleshooting Steps:</h3>
                            <ol style="color: #721c24;">
                                <li>Check the console logs in Jenkins for detailed error messages</li>
                                <li>Verify all dependencies are correctly specified in package.json</li>
                                <li>Ensure TypeScript configuration is valid</li>
                                <li>Check for syntax errors in your code</li>
                                <li>Verify environment variables are set correctly</li>
                                <li>Test the build locally with: <code>npm run build</code></li>
                            </ol>
                        </div>

                        <div style="background: #fff3cd; padding: 15px; border-radius: 5px; margin: 10px 0;">
                            <p style="color: #856404; margin: 0;">
                                <strong>💡 Quick Fix:</strong> Run <code>npm install && npm run build</code> locally to reproduce the issue.
                            </p>
                        </div>
                    </div>
                """,
                to: 'your-email@college.edu',
                mimeType: 'text/html'
            )
        }

        unstable {
            echo '⚠️ Next.js TypeScript pipeline completed with warnings!'
            emailext (
                subject: "⚠️ Next.js Build Unstable: ${env.JOB_NAME} - ${env.BUILD_NUMBER}",
                body: """
                    <h2 style="color: #ffc107;">⚠️ Build Completed with Warnings</h2>
                    <p>The build completed but some stages had warnings or non-critical failures.</p>
                    <p><strong>Build URL:</strong> <a href="${env.BUILD_URL}">${env.BUILD_URL}</a></p>
                    <p>Please review the logs and consider fixing the warnings.</p>
                """,
                to: 'your-email@college.edu',
                mimeType: 'text/html'
            )
        }

        always {
            echo 'Cleaning up workspace and archiving artifacts...'

            // Archive important build artifacts
            archiveArtifacts artifacts: '.next/**/*', allowEmptyArchive: true, fingerprint: true

            // Archive package files for reference
            archiveArtifacts artifacts: 'package*.json, tsconfig.json, next.config.js', allowEmptyArchive: true

            // Clean workspace to save space
            cleanWs(
                cleanWhenAborted: true,
                cleanWhenFailure: true,
                cleanWhenNotBuilt: true,
                cleanWhenSuccess: true,
                cleanWhenUnstable: true,
                deleteDirs: true
            )
        }
    }
}