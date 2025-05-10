# Use the official Apache Tomcat base image
FROM tomcat:9.0

# Set environment variables (optional)
ENV JAVA_OPTS="-Xms512m -Xmx1024m"

# Copy the built WAR file into Tomcat's webapps directory
COPY target/your-app.war /usr/local/tomcat/webapps/

# Expose Tomcat's default port
EXPOSE 8080

# Start Tomcat when the container runs
CMD ["catalina.sh", "run"]
