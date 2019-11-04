FROM busybox:latest
ENV APP_ROOT /code
WORKDIR /data
COPY AOP-DB.ttl .
COPY AOP-DB.ttl.graph .
COPY docker-entrypoint.sh ${APP_ROOT}/
WORKDIR ${APP_ROOT}
CMD sh docker-entrypoint.sh
