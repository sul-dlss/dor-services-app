pipeline {
  agent any

  environment {
    PROJECT = 'sul-dlss/dor-services-app'
  }

  stages {
    stage('Deploy to stage on merges to main') {
      environment {
        DEPLOY_ENVIRONMENT = 'stage'
      }

      when {
        // Comment this line and uncomment the following to turn continuous deployment off
        // branch 'main'
        expression { return null }
      }

      steps {
        checkout scm

        sshagent (['sul-devops-team', 'sul-continuous-deployment']){
          sh '''#!/bin/bash -l
          export DEPLOY=1
          
          # Load RVM
          rvm use 3.4.1@dor-services-app --create
          gem install bundler
          
          bundle config set without production
          bundle install
          
          # Deploy it
          bundle exec cap $DEPLOY_ENVIRONMENT deploy
          '''
        }
      }

      post {
        always {
          build job: '/Continuous Deployment/Slack Deployment Notification', parameters: [
            string(name: 'PROJECT', value: env.PROJECT),
            string(name: 'GIT_COMMIT', value: env.GIT_COMMIT),
            string(name: 'GIT_URL', value: env.GIT_URL),
            string(name: 'GIT_PREVIOUS_SUCCESSFUL_COMMIT', value: env.GIT_PREVIOUS_SUCCESSFUL_COMMIT),
            string(name: 'DEPLOY_ENVIRONMENT', value: env.DEPLOY_ENVIRONMENT),
            string(name: 'TAG_NAME', value: env.TAG_NAME),
            booleanParam(name: 'SUCCESS', value: currentBuild.resultIsBetterOrEqualTo('SUCCESS')),
            string(name: 'RUN_DISPLAY_URL', value: env.RUN_DISPLAY_URL)
          ]
        }
      }
    }
  }
}
