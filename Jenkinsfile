#!/usr/bin/env groovy

String DEFAULT_NAMESPACE = 'fedoraci'

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
        ansiColor('xterm')
    }
    triggers {
        // Each 3 hours
        cron('H H/3 * * *')
    }
    parameters {
        string(name: 'USER', defaultValue: '', trim: true, description: 'quay.io user')
        string(name: 'PASSWORD', defaultValue: '', trim: true, description: 'quay.io password')
        string(name: 'PASSWORD', defaultValue: '', trim: true, description: 'quay.io password')
        string(name: 'NAMESPACE', defaultValue: '', trim: true, description: 'quay.io destination namespace')
        string(name: 'FILE', defaultValue: '', trim: true, description: 'File with list of repos to mirror')
    }
    stages {
        stage('Prepare') {
            steps {
                cleanWs deleteDirs: true
                echo """Running ${env.BUILD_ID} on ${env.JENKINS_URL}
                """
                sh 'cat /etc/os-release'
                sh 'env'
            }
        }
        stage('Mirroring') {
            steps {
                sh "./mirror-images.sh --namespace '${params.NAMESPACE}' -u '${params.USER}' -p '${params.PASSWORD}' -f '${params.FILE}' | tee log.txt"
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
