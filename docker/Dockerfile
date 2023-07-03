FROM postgres: bitnami/postgresql:15.1.0
COPY conf.sql /docker-entrypoint-initdb.d/
RUN chmod a+r /docker-entrypoint-initdb.d/conf.sql