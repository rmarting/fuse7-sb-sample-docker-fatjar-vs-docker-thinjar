FROM registry.access.redhat.com/fuse7/fuse-java-openshift:1.2

# Fuse 7, Spring Boot and Third Party Dependencies
COPY target/lib /deployments/lib

# Application
COPY target/*.jar /deployments
