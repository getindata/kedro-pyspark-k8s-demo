#!/bin/bash -x

env | grep SPARK_JAVA_OPT_ | sort -t_ -k4 -n | sed 's/[^=]*=\(.*\)/\1/g' > /tmp/java_opts.txt
readarray -t SPARK_EXECUTOR_JAVA_OPTS < /tmp/java_opts.txt

exec java \
  "${SPARK_EXECUTOR_JAVA_OPTS[@]}" \
  -Xms$SPARK_EXECUTOR_MEMORY \
  -Xmx$SPARK_EXECUTOR_MEMORY \
  -cp "/usr/local/lib/python3.9/site-packages/pyspark/jars/*" \
  org.apache.spark.executor.CoarseGrainedExecutorBackend \
  --driver-url $SPARK_DRIVER_URL \
  --executor-id $SPARK_EXECUTOR_ID \
  --cores $SPARK_EXECUTOR_CORES \
  --app-id $SPARK_APPLICATION_ID \
  --hostname $SPARK_EXECUTOR_POD_IP \
  --resourceProfileId $SPARK_RESOURCE_PROFILE_ID 
