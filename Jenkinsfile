node {
	// Pipeline Properties
	properties([buildDiscarder(logRotator(artifactDaysToKeepStr: '', artifactNumToKeepStr: '', daysToKeepStr: '10', numToKeepStr: '5')), pipelineTriggers([[$class: 'PeriodicFolderTrigger', interval: '1d']])])
	
        // Get Artifactory server instance, defined in the Artifactory Plugin administration page.
	def server = Artifactory.server "artifactory"
        // Create an Artifactory Maven instance.
        def rtMaven = Artifactory.newMavenBuild()
        def buildInfo
	
	stage('Initialize') {
        	rtMaven.tool = "maven"
        	rtMaven.deployer releaseRepo:'libs-release-local', snapshotRepo:'libs-snapshot-local', server: server
        	rtMaven.resolver releaseRepo:'libs-release', snapshotRepo:'libs-snapshot', server: server
		slackSend channel: 'devops-case-study-group', failOnError: true, message: "${env.JOB_NAME} ${env.BUILD_NUMBER} (<${env.BUILD_URL}|Open>) ==>> Pipeline Started", tokenCredentialId: 'SLACK-TOKEN'
    	}
    
    	stage('GitHub Checkout') {
        	git url: 'https://github.com/barath147/webapp.git'
		slackSend channel: 'devops-case-study-group', failOnError: true, message: "${env.JOB_NAME} ${env.BUILD_NUMBER} (<${env.BUILD_URL}|Open>) ==>> GitHub Checkout Complete", tokenCredentialId: 'SLACK-TOKEN'
    	}
	
	stage('Build & Static Code Analysis') {
		withCredentials([usernamePassword(credentialsId: 'SONAR-QUBE-CREDS', passwordVariable: 'SONAR_PASS', usernameVariable: 'SONAR_USER')]) {
		withSonarQubeEnv('SonarQube') {
			sh 'mvn clean install $SONAR_MAVEN_GOAL -Dsonar.host.url=$SONAR_HOST_URL -Dsonar.login=$SONAR_USER -Dsonar.password=$SONAR_PASS -Dsonar.sources=. -Dsonar.tests=. -Dsonar.test.inclusions=**/test/java/servlet/createpage_junit.java -Dsonar.exclusions=**/test/java/servlet/createpage_junit.java'
		}
		}
		slackSend channel: 'devops-case-study-group', failOnError: true, message: "${env.JOB_NAME} ${env.BUILD_NUMBER} (<${env.BUILD_URL}|Open>) ==>> Maven Build and SonarQube Scan Complete", tokenCredentialId: 'SLACK-TOKEN'
	}
	
	stage('Deploy QA Container') {
		deploy adapters: [tomcat7(credentialsId: 'TOMCAT-CREDS', path: '', url: 'http://3.21.154.146:8080')], contextPath: '/QAWebapp', onFailure: false, war: '**/*.war'
		slackSend channel: 'devops-case-study-group', failOnError: true, message: "${env.JOB_NAME} ${env.BUILD_NUMBER} (<${env.BUILD_URL}|Open>) ==>> QA Deployment Complete", tokenCredentialId: 'SLACK-TOKEN'
	}
	
    	stage('Upload to Artifactory') {
        	buildInfo = rtMaven.run pom: 'pom.xml', goals: 'clean install'
		server.publishBuildInfo buildInfo
		slackSend channel: 'devops-case-study-group', failOnError: true, message: "${env.JOB_NAME} ${env.BUILD_NUMBER} (<${env.BUILD_URL}|Open>) ==>> JFrog Artifact Upload Complete", tokenCredentialId: 'SLACK-TOKEN'
    	}
	
	stage('Quality & Performance Testing') {
		sh 'mvn clean compile test -f functionaltest/pom.xml'
		publishHTML([allowMissing: false, alwaysLinkToLastBuild: true, keepAll: true, reportDir: '\\target\\surefire-reports\\', reportFiles: 'index.html', reportName: 'HTML Report', reportTitles: ''])
		blazeMeterTest credentialsId: 'BLAZEMETER-KEY', getJtl: true, getJunit: true, testId: '7900226.taurus', workspaceId: '468388'
		slackSend channel: 'devops-case-study-group', failOnError: true, message: "${env.JOB_NAME} ${env.BUILD_NUMBER} (<${env.BUILD_URL}|Open>) ==>> Quality and Performance Testing Complete", tokenCredentialId: 'SLACK-TOKEN'
		
	}
	
	stage('Deploy PROD Container') {
		deploy adapters: [tomcat7(credentialsId: 'TOMCAT-CREDS', path: '', url: 'http://18.191.219.231:8080')], contextPath: '/ProdWebapp', onFailure: false, war: '**/*.war'
		slackSend channel: 'devops-case-study-group', failOnError: true, message: "${env.JOB_NAME} ${env.BUILD_NUMBER} (<${env.BUILD_URL}|Open>) ==>> PROD Deployment Complete", tokenCredentialId: 'SLACK-TOKEN'
	}
	
	stage('Acceptance Testing') {
		sh 'mvn clean compile test -f Acceptancetest/pom.xml'
		publishHTML([allowMissing: false, alwaysLinkToLastBuild: true, keepAll: true, reportDir: '\\Acceptancetest\\target\\surefire-reports\\', reportFiles: 'index.html', reportName: 'HTML Report', reportTitles: ''])
		slackSend channel: 'devops-case-study-group', failOnError: true, message: "${env.JOB_NAME} ${env.BUILD_NUMBER} (<${env.BUILD_URL}|Open>) ==>> Acceptance Testing Complete", tokenCredentialId: 'SLACK-TOKEN'
		
	}
	
    	stage('Publish Build Info') {
        	slackSend channel: 'devops-case-study-group', failOnError: true, message: "${env.JOB_NAME} ${env.BUILD_NUMBER} (<${env.BUILD_URL}|Open>) ==>> Pipeline Complete", tokenCredentialId: 'SLACK-TOKEN'
    	}
    }
