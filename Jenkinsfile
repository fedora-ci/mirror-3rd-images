#!/usr/bin/env groovy

String DEFAULT_NAMESPACE = 'fedoraci'
String DEFAULT_FILE = 'mirror-images.list'

// Specified param take prio over jenkins secrets
String getSecret(String id, String param) {
  if (param?.trim()) {
    echo "Use present secret id == ${id}"
    return param?.trim()
  }
  try {
    withCredentials([string(credentialsId: id, variable: 'secret')]) {
      echo "Retrieved from Jenkins secret id == ${id}"
      return "${secret}"
    }
  } catch (_) {
    echo "Cannot retrieve from Jenkins secret id == ${id}"
    return ''
  }
}

properties(
    [
       [$class: 'ThrottleJobProperty',
            categories: [],
            limitOneJobWithMatchingParams: false,
            maxConcurrentPerNode: 1,
            maxConcurrentTotal: 1,
            paramsToUseForLimit: '',
            throttleEnabled: true,
            throttleOption: 'project'],
    ]
)

pipeline {
    agent { label 'centos8' }
    options {
        buildDiscarder(logRotator(numToKeepStr:'100'))
        timeout(time: 3, unit: 'HOURS')
    }
    triggers {
        // Each 3 hours
        cron('H H/3 * * *')
    }
    parameters {
        string(name: 'USER', defaultValue: '', trim: true, description: 'quay.io user')
        string(name: 'PASSWORD', defaultValue: '', trim: true, description: 'quay.io password')
        string(name: 'NAMESPACE', defaultValue: DEFAULT_NAMESPACE, trim: true, description: 'quay.io destination namespace')
        string(name: 'FILE', defaultValue: DEFAULT_FILE, trim: true, description: 'File with list of repos to mirror')
    }
    stages {
        stage('Prepare') {
            steps {
                cleanWs deleteDirs: true
                echo """Running ${env.BUILD_ID} on ${env.JENKINS_URL}
                """
                sh 'cat /etc/os-release'
                sh 'env'
                script {
                    retry(10) {
                        try {
                            git branch: 'master', url: 'https://github.com/fedora-ci/mirror-3rd-images.git'
                        } catch (e) {
                            echo 'Err: cloning repo failed with Error: ' + e.toString()
                            sleep time: 5, unit: 'SECONDS'
                            throw e
                        }
                    }
                }
            }
        }
        stage('Mirroring') {
            steps {
                script {
                    env.SYNC_USER = getSecret('mirror-3rd-images-user', params.USER);
                    env.SYNC_PASSWORD = getSecret('mirror-3rd-images-password', params.PASSWORD);
                    echo env.USER
                }
                sh "./mirror-images.sh --namespace '${params.NAMESPACE}' -f '${params.FILE}' 2>&1 | tee log.txt"
            }
        }
    }
    post {
        always {
            script {
                Thread.currentThread().setContextClassLoader(getClass().getClassLoader());
            }
            archiveArtifacts allowEmptyArchive: true, artifacts: 'log.txt', fingerprint: true
        }
    }
}
