# Scenario 3: Spark on k8s

### Environment setup
Kedro PySpark / Iris
https://github.com/quantumblacklabs/kedro-starter-pyspark-iris

```
# Create a directory for your project
mkdir workshop

# Install the virtualenv package  
pip install virtualenv 

# Create the virtualenv with the specific Python version
virtualenv workshop-env --python=python3.9  

# Activate the virtualenv
source workshop-env/bin/activate

# Go to the working directory
cd workshop
```

`conda deactivate` if needed.

### Install Kedro
Note: remember use Kedro in the specific version: `kedro==0.18.2`
```
# Install the Kedro Python package in the virtual environment
pip install 'kedro==0.18.2'
```

### Create new project
```
kedro new --starter=pyspark-iris
```

### Install project dependencies
Please install the project dependencies, defined in the `src/requirements.txt` file.  
Note: in the future you’ll add new Python packages there.

```  
# Make sure you’re in your project’s main folder
cd iris

# Add the following dependencies in src/requirements.txt
kedro-docker==0.3.0
pyspark==3.2.2

# Install project dependencies
pip install -r src/requirements.txt
```

### Run pipeline locally
```
kedro run
# exit with error
```

### Prepare Docker image

Initialize plugin. It will add `Dockerfile` and `.dockerignore` files:
```
kedro docker init
```

Adjust `.dockerignore `
```
# Add this line to include the input file inside Docker container
# In other scenarios it will be optional if you'll read input data from external storage, i.e. GCS

!data/01_raw
```

Adjust `Dockerfile `

```
ARG BASE_IMAGE=python:3.9-buster

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

# copy the whole project except what is in .dockerignore
WORKDIR /home/kedro

COPY . .

RUN chown -R kedro:${KEDRO_GID} /home/kedro

USER kedro

RUN chmod -R a+w /home/kedro

EXPOSE 8888

CMD ["kedro", "run"]
```

Build docker container

```
docker build \
	-t gcr.io/gid-ml-ops-sandbox/pyspark-k8s:20221006 \
	.

docker push gcr.io/gid-ml-ops-sandbox/pyspark-k8s:20221006
```

