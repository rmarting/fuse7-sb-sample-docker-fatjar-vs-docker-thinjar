# Fuse 7 Images with FatJar versus ThinJar

Sample repo of [Red Hat Developer Blog Post](https://developers.redhat.com/blog/2019/04/26/optimizing-red-hat-fuse-7-spring-boot-container-images/)

This example demonstrates how build Fuse 7 on Spring Boot images with two different approaches:

* **FatJar**: Application packaged as original Spring Boot Application
* **ThinJar**: Application divided into application and dependencies

This example tries to show you how both approaches create different layers in Docker images. Those
layers could help you in your deployment pipelines.

The quickstart uses Spring Boot to configure a little application that includes a Camel route that triggers a message every 5th second, and routes the message to a log.

## Requeriments

This project needs a Docker daemon to build the final images. Please review your environment
to have access to a Docker daemon.

## Building a FatJar Image

The example can be built with

    mvn clean package -Pfuse7-sb-fatjar

### Inspecting your image

Listing your current images

    $ docker images
    REPOSITORY              TAG             IMAGE ID      CREATED              SIZE
    fuse7-sb-sample-fatjar  1.0.0-SNAPSHOT  83b0a7014e66  About a minute ago   472MB

History of your fatjar image

    $ docker image history fuse7-sb-sample-fatjar:1.0.0-SNAPSHOT 
    IMAGE         CREATED        CREATED BY                                      SIZE                COMMENT
    83b0a7014e66  3 minutes ago  /bin/sh -c #(nop) COPY dir:6f1bc8060e84f24fd…   22.5MB              
    3acce9532a02  5 weeks ago                                                    29.7MB              
    <missing>     5 weeks ago                                                    204MB               
    <missing>     5 weeks ago                                                    12.6MB              
    <missing>     5 weeks ago                                                    2.92kB              
    <missing>     5 weeks ago                                                    203MB               Imported from -

## Building a ThinJar Image

The example can be built with

    mvn clean package -Pfuse7-sb-thinjar

### Inspecting your image

Listing your current images

    $ docker images
    REPOSITORY              TAG             IMAGE ID      CREATED              SIZE
    fuse7-sb-sample-thinjar 1.0.0-SNAPSHOT  3d1f14d211d3  4 seconds ago        472MB

History of your thinjar image

    $ docker image history fuse7-sb-sample-thinjar:1.0.0-SNAPSHOT 
    IMAGE         CREATED         CREATED BY                                      SIZE                COMMENT
    3d1f14d211d3  45 seconds ago  /bin/sh -c #(nop) COPY file:a8e6ca81de366678…   5.92kB              
    8f85633e632f  45 seconds ago  /bin/sh -c #(nop) COPY dir:9371efeba146b0c49…   22.4MB              
    3acce9532a02  5 weeks ago                                                     29.7MB              
    <missing>     5 weeks ago                                                     204MB               
    <missing>     5 weeks ago                                                     12.6MB              
    <missing>     5 weeks ago                                                     2.92kB              
    <missing>     5 weeks ago                                                     203MB               Imported from -

## Running images

The example can be run using:

    $ docker run fuse7-sb-sample-fatjar:1.0.0-SNAPSHOT
    $ docker run fuse7-sb-sample-thinjar:1.0.0-SNAPSHOT

When the containers are running, you can inspect the logs with

    docker logs <name of container>

Both cases should log similar messages:

    Starting the Java application using /opt/run-java/run-java.sh ...
    exec java -javaagent:/opt/jolokia/jolokia.jar=config=/opt/jolokia/etc/jolokia.properties -javaagent:/opt/prometheus/jmx_prometheus_javaagent.jar=9779:/opt/prometheus/prometheus-config.yml -XX:+UseParallelGC -XX:GCTimeRatio=4 -XX:AdaptiveSizePolicyWeight=9
    0 -XX:MinHeapFreeRatio=20 -XX:MaxHeapFreeRatio=40 -XX:+ExitOnOutOfMemoryError -cp . -jar /deployments/fuse7-sb-sample-docker-fatjar-vs-docker-thinjar-1.0.0-SNAPSHOT.jar
    I> No access restrictor found, access to any MBean is allowed
    Jolokia: Agent started with URL http://172.17.0.2:8778/jolokia/
    
      .   ____          _            __ _ _
     /\\ / ___'_ __ _ _(_)_ __  __ _ \ \ \ \
    ( ( )\___ | '_ | '_| | '_ \/ _` | \ \ \ \
     \\/  ___)| |_)| | | | | || (_| |  ) ) ) )
      '  |____| .__|_| |_|_| |_\__, | / / / /
     =========|_|==============|___/=/_/_/_/
     :: Spring Boot ::       (v1.5.16.RELEASE)
    
    09:44:19.314 [main] INFO  org.jboss.fuse7.samples.Application - Starting Application on 9c92300a6c84 with PID 1 (/deployments/fuse7-sb-sample-docker-fatjar-vs-docker-thinjar-1.0.0-SNAPSHOT.jar started by jboss in /deployments)
    09:44:19.318 [main] INFO  org.jboss.fuse7.samples.Application - No active profile set, falling back to default profiles: default
    ...
    09:44:28.993 [main] INFO  o.s.b.a.e.jmx.EndpointMBeanExporter - Located managed bean 'healthEndpoint': registering with JMX server as MBean [org.springframework.boot:type=Endpoint,name=healthEndpoint]
    09:44:29.133 [main] INFO  o.s.b.c.e.u.UndertowEmbeddedServletContainer - Undertow started on port(s) 8080 (http)
    09:44:29.138 [main] INFO  org.jboss.fuse7.samples.Application - Started Application in 10.313 seconds (JVM running for 11.374)
    09:44:29.802 [Camel (Fuse7-SB-Sample-Docker-FatJar-vs-ThinJar) thread #1 - timer://foo] INFO  route1 - >>> Hello World


# Comparing Docker Images

Initial conclusions:

* Final images have the same final size. No difference as final image.
* Same application running

Main Differences:

* Each time we build the fatjar application the layer with the application is replaced completely (aroung 22Mb)

    $ mvn clean package -Pdocker-fatjar
    $ docker image history fuse7-sb-sample-fatjar:1.0.0-SNAPSHOT 
    IMAGE          CREATED        CREATED BY                                      SIZE                COMMENT
    fc90862260bf   17 seconds ago /bin/sh -c #(nop) COPY dir:23bf52db17b0a0aaa…   22.5MB              

* Each time we build the thinjar application, only the layer with the application is replace completely (around 6Kb).
Docker cache is used and then only one layer is changed in the final image.

    $ mvn clean package -Pdocker-thinjar
    $ docker image history fuse7-sb-sample-thinjar:1.0.0-SNAPSHOT
    IMAGE          CREATED        CREATED BY                                      SIZE                COMMENT
    b62a83bd5286   8 seconds ago  /bin/sh -c #(nop) COPY file:23ff2a06a7e2e24d…   5.92kB              
    8f85633e632f   16 minutes ago /bin/sh -c #(nop) COPY dir:9371efeba146b0c49…   22.4MB    
    
We could improve our deployment pipelines if we use a thinjar strategy for our classes. Normally
the dependencies only change in few cases and they are very stable.

This sample is very simple and small, but sometimes your applications could be so heavies and then
build and deployment process will take longer time and increase the resources.
