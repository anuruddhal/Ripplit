ARG BALLERINA_VERSION=2201.12.2

FROM ballerina/ballerina:${BALLERINA_VERSION} AS ballerina-tools-build
LABEL maintainer "ballerina.io"

USER root

COPY ./ /home/work-dir/sentiment_api
WORKDIR /home/work-dir/sentiment_api
RUN bal build

FROM ballerina/jvm-runtime:3.0

RUN mkdir -p /work-dir \
    && addgroup troupe \
    && adduser -S -s /bin/bash -g 'ballerina' -G troupe -D ballerina \
    && apk upgrade \
    && chown -R ballerina:troupe /work-dir

USER ballerina

WORKDIR /home/work-dir/
COPY --from=ballerina-tools-build /home/work-dir/sentiment_api/target/bin/sentimentapi.jar /home/work-dir/
COPY --from=ballerina-tools-build /home/work-dir/sentiment_api/Config.toml /home/work-dir/

EXPOSE 6060
EXPOSE 6061

ENV JAVA_TOOL_OPTIONS "-XX:+UseContainerSupport -XX:MaxRAMPercentage=80.0 -XX:TieredStopAtLevel=1"

CMD [ "java", "-jar", "sentimentapi.jar"]