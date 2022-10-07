ARG BASE_IMAGE=python:3.9-slim

FROM $BASE_IMAGE

# overwrite default Dataproc PYSPARK_PYTHON path
ENV PYSPARK_PYTHON /usr/local/bin/python

ENV SPARK_EXTRA_CLASSPATH /usr/local/lib/python3.9/site-packages/pyspark/jars/*


# install project requirements
COPY src/requirements.txt /tmp/requirements.txt
RUN pip install -r /tmp/requirements.txt && rm -f /tmp/requirements.txt

# (Required) Install utilities required by Spark scripts.
RUN apt update && apt install -y procps tini openjdk-11-jre-headless

# add kedro user
ARG KEDRO_UID=999
ARG KEDRO_GID=0

RUN groupadd -f -g ${KEDRO_GID} kedro_group && \
    useradd -d /home/kedro -s /bin/bash -g ${KEDRO_GID} -u ${KEDRO_UID} kedro

# (Required) Create the 'spark' group/user.
# The GID and UID must be 1099. Home directory is required.
RUN groupadd -g 1099 spark
RUN useradd -u 1099 -g 1099 -d /home/spark -m spark
#USER spark

COPY scripts/spark-executor-entrypoint.bash /usr/local/bin/executor

# copy the whole project except what is in .dockerignore
WORKDIR /home/kedro

COPY . .

RUN chown -R kedro:${KEDRO_GID} /home/kedro

USER kedro

RUN chmod -R a+w /home/kedro

EXPOSE 8888

CMD ["kedro", "run"]
