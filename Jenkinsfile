node {
	stage('Initialize Pipeline') {
		deleteDir()
		properties([buildDiscarder(logRotator(artifactDaysToKeepStr: '', artifactNumToKeepStr: '', daysToKeepStr: '10', numToKeepStr: '10')), disableConcurrentBuilds(), pipelineTriggers([githubPush(), pollSCM('')])])
		server = Artifactory.server "artifactory"
        	rtMaven = Artifactory.newMavenBuild()
        	rtMaven.tool = "maven"
        	rtMaven.deployer releaseRepo:'libs-release-local', snapshotRepo:'libs-snapshot-local', server: server
        	rtMaven.resolver releaseRepo:'libs-release', snapshotRepo:'libs-snapshot', server: server
		slackSend channel: 'devops-case-study-group', failOnError: true, message: "${env.JOB_NAME} ${env.BUILD_NUMBER} (<${env.BUILD_URL}|Open>) ==>> Pipeline Initialized", tokenCredentialId: 'SLACK-TOKEN'
    	}
    
    	stage('Code Checkout & Build') {
        	git branch: "${env.BRANCH_NAME}", credentialsId: 'GITHUB-CREDS', url: 'https://github.com/barath147/WebApp.git'
		sh 'mvn clean install'
		slackSend channel: 'devops-case-study-group', failOnError: true, message: "${env.JOB_NAME} ${env.BUILD_NUMBER} (<${env.BUILD_URL}|Open>) ==>> GitHub Checkout and Maven Build Complete", tokenCredentialId: 'SLACK-TOKEN'
    	}
	
	stage('Static Code Analysis') {
		withCredentials([usernamePassword(credentialsId: 'SONAR-QUBE-CREDS', passwordVariable: 'SONAR_PASS', usernameVariable: 'SONAR_USER')]) {
		withSonarQubeEnv('SonarQube') {
			sh 'mvn $SONAR_MAVEN_GOAL -Dsonar.host.url=$SONAR_HOST_URL -Dsonar.login=$SONAR_USER -Dsonar.password=$SONAR_PASS -Dsonar.sources=. -Dsonar.tests=. -Dsonar.test.inclusions=**/test/java/servlet/createpage_junit.java -Dsonar.exclusions=**/test/java/servlet/createpage_junit.java'
		}
		}
		slackSend channel: 'devops-case-study-group', failOnError: true, message: "${env.JOB_NAME} ${env.BUILD_NUMBER} (<${env.BUILD_URL}|Open>) ==>> SonarQube Static Code Analysis Scan Complete", tokenCredentialId: 'SLACK-TOKEN'
	}
	
	stage('DeployAppTo QA') {
		deploy adapters: [tomcat7(credentialsId: 'TOMCAT-CREDS', path: '', url: 'http://3.21.154.146:8080')], contextPath: '/QAWebapp', onFailure: false, war: '**/*.war'
		jiraSendDeploymentInfo environmentId: 'QA', environmentName: 'QA', environmentType: 'testing', site: 'devopscasestudy.atlassian.net'
		slackSend channel: 'devops-case-study-group', failOnError: true, message: "${env.JOB_NAME} ${env.BUILD_NUMBER} (<${env.BUILD_URL}|Open>) ==>> QA Deployment Complete", tokenCredentialId: 'SLACK-TOKEN'
	}
	
    	stage('UploadTo Artifactory') {
        	buildInfo = rtMaven.run pom: 'pom.xml', goals: 'clean install'
		server.publishBuildInfo buildInfo
		slackSend channel: 'devops-case-study-group', failOnError: true, message: "${env.JOB_NAME} ${env.BUILD_NUMBER} (<${env.BUILD_URL}|Open>) ==>> JFrog Artifactory Upload Complete", tokenCredentialId: 'SLACK-TOKEN'
    	}
	
	stage('Quality & Performance Testing') {
		sh 'mvn clean compile test -f functionaltest/pom.xml'
		publishHTML([allowMissing: false, alwaysLinkToLastBuild: true, keepAll: true, reportDir: '\\target\\surefire-reports\\', reportFiles: 'index.html', reportName: 'Quality Test Report', reportTitles: ''])
		blazeMeterTest credentialsId: 'BLAZEMETER-KEY', getJtl: true, getJunit: true, testId: '7903978.taurus', workspaceId: '468408'
		slackSend channel: 'devops-case-study-group', failOnError: true, message: "${env.JOB_NAME} ${env.BUILD_NUMBER} (<${env.BUILD_URL}|Open>) ==>> Quality and Performance Testing Complete", tokenCredentialId: 'SLACK-TOKEN'
		
	}
	
	stage('DeployAppTo PROD') {
		deploy adapters: [tomcat7(credentialsId: 'TOMCAT-CREDS', path: '', url: 'http://18.191.219.231:8080')], contextPath: '/ProdWebapp', onFailure: false, war: '**/*.war'
		jiraSendDeploymentInfo environmentId: 'PROD', environmentName: 'PROD', environmentType: 'production', site: 'devopscasestudy.atlassian.net'
		slackSend channel: 'devops-case-study-group', failOnError: true, message: "${env.JOB_NAME} ${env.BUILD_NUMBER} (<${env.BUILD_URL}|Open>) ==>> PROD Deployment Complete", tokenCredentialId: 'SLACK-TOKEN'
	}
	
	stage('Acceptance Testing') {
		sh 'mvn clean compile test -f Acceptancetest/pom.xml'
		publishHTML([allowMissing: false, alwaysLinkToLastBuild: true, keepAll: true, reportDir: '\\Acceptancetest\\target\\surefire-reports\\', reportFiles: 'index.html', reportName: 'Acceptance Test Report', reportTitles: ''])
		slackSend channel: 'devops-case-study-group', failOnError: true, message: "${env.JOB_NAME} ${env.BUILD_NUMBER} (<${env.BUILD_URL}|Open>) ==>> Acceptance Testing Complete", tokenCredentialId: 'SLACK-TOKEN'
		
	}
	
    	stage('Publish Build Info') {
		jiraSendBuildInfo branch: "${env.BRANCH_NAME}", site: 'devopscasestudy.atlassian.net'
        	slackSend channel: 'devops-case-study-group', failOnError: true, message: "${env.JOB_NAME} ${env.BUILD_NUMBER} (<${env.BUILD_URL}|Open>) ==>> Pipeline Complete", tokenCredentialId: 'SLACK-TOKEN'
    	}
    }
