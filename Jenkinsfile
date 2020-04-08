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
    	}
    
    	stage('GitHub Checkout') {
        	git url: 'https://github.com/barath147/webapp.git'
    	}
	
	stage('Build & Static Code Analysis') {
		withCredentials([usernamePassword(credentialsId: 'SONAR-QUBE-CREDS', passwordVariable: 'SONAR_PASS', usernameVariable: 'SONAR_USER')]) {
		withSonarQubeEnv('SonarQube') {
			sh 'mvn clean install $SONAR_MAVEN_GOAL -Dsonar.host.url=$SONAR_HOST_URL -Dsonar.login=$SONAR_USER -Dsonar.password=$SONAR_PASS -Dsonar.sources=. -Dsonar.tests=. -Dsonar.test.inclusions=**/test/java/servlet/createpage_junit.java -Dsonar.exclusions=**/test/java/servlet/createpage_junit.java'
		}
		}
	}
	
	stage('Deploy QA Container') {
		deploy adapters: [tomcat7(credentialsId: 'TOMCAT-CREDS', path: '', url: 'http://3.21.154.146:8080')], contextPath: '/QAWebapp', onFailure: false, war: '**/*.war'
	}
	
    	stage('Upload to Artifactory') {
        	buildInfo = rtMaven.run pom: 'pom.xml', goals: 'clean install'
		server.publishBuildInfo buildInfo
    	}
	
	stage('Quality & Performance Testing') {
		sh 'mvn clean compile test -f functionaltest/pom.xml'
		publishHTML([allowMissing: false, alwaysLinkToLastBuild: true, keepAll: true, reportDir: '\\target\\surefire-reports\\', reportFiles: 'index.html', reportName: 'HTML Report', reportTitles: ''])
		blazeMeterTest credentialsId: 'BLAZEMETER-KEY', getJtl: true, getJunit: true, testId: '7900226.taurus', workspaceId: '468388'
	}
	
	stage('Deploy PROD Container') {
		deploy adapters: [tomcat7(credentialsId: 'TOMCAT-CREDS', path: '', url: 'http://18.191.219.231:8080')], contextPath: '/ProdWebapp', onFailure: false, war: '**/*.war'
	}
	
	stage('Acceptance Testing') {
		sh 'mvn clean compile test -f Acceptancetest/pom.xml'
		publishHTML([allowMissing: false, alwaysLinkToLastBuild: true, keepAll: true, reportDir: '\\Acceptancetest\\target\\surefire-reports\\', reportFiles: 'index.html', reportName: 'HTML Report', reportTitles: ''])
		
	}
	
    	stage('Publish Build Info') {
        	server.publishBuildInfo buildInfo
    	}
    }
