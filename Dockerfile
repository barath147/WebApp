FROM tomcat:9-jre8-slim

LABEL maintainer="BarathKumar"

COPY ./target/JavaWebApp-1.0.war /usr/local/tomcat/webapps/WebApp.war

EXPOSE 8080

CMD ["catalina.sh", "run"]