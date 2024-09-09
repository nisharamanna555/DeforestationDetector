# Step 1: Base image
FROM python:3.10-slim

# Set environment variables
ENV PYTHONUNBUFFERED=1
ENV JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64
ENV SPARK_VERSION=3.5.2
ENV HADOOP_VERSION=3
ENV SPARK_PACKAGE=spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}
ENV SPARK_HOME=/usr/local/spark

# Step 2: Install system dependencies
RUN apt-get update && apt-get install -y \
    default-jdk \
    curl \
    git \
    wget \
    gnupg \
    libhdf5-dev \
    libpng-dev \
    libjpeg-dev \
    python3-dev \
    && rm -rf /var/lib/apt/lists/*

# Step 3: Install Miniforge (to manage Python packages and Jupyter)
RUN wget https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Linux-x86_64.sh -O Miniforge3.sh && \
    bash Miniforge3.sh -b -p /opt/conda && \
    rm Miniforge3.sh

ENV PATH="/opt/conda/bin:$PATH"

# Step 4: Install Spark
# # RUN curl -O https://dlcdn.apache.org/spark/spark-3.5.2/spark-3.5.2-bin-hadoop3.tgz && \
# #     tar zxvf spark-3.1.2-bin-hadoop2.7.tgz && \
# #     mv spark-3.1.2-bin-hadoop2.7 /usr/local/spark && \
# #     rm spark-3.1.2-bin-hadoop2.7.tgz

RUN wget https://archive.apache.org/dist/spark/spark-${SPARK_VERSION}/${SPARK_PACKAGE}.tgz \
    && tar -xzf ${SPARK_PACKAGE}.tgz \
    && mv ${SPARK_PACKAGE} /usr/local/spark \
    && rm ${SPARK_PACKAGE}.tgz

ENV SPARK_HOME="/usr/local/spark"
ENV PATH="$SPARK_HOME/bin:$PATH"

# Step 5: Set environment variables for Java, Python, Spark
ENV JAVA_HOME="/usr/lib/jvm/java-11-openjdk-amd64"
ENV PYTHON_PATH="/opt/conda/bin/python3"
ENV PATH="/opt/conda/bin:/usr/local/spark/bin:/usr/lib/jvm/java-11-openjdk-amd64/bin:$PATH"

# Step 6: Install MongoDB and Jupyter dependencies
RUN conda install -y jupyter && \
    pip install pymongo gridfs gunicorn Flask geemap requests

# Install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Step 7: Copy the app files
WORKDIR /app
COPY . .

# Step 8: Expose the port and run the app
EXPOSE 5000
CMD ["gunicorn", "-w", "4", "-b", "0.0.0.0:5000", "app:app"]

# # Use an official Python runtime as a parent image
# FROM python:3.10-slim

# # Set environment variables
# ENV PYTHONUNBUFFERED=1
# ENV JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64
# ENV SPARK_VERSION=3.5.2
# ENV HADOOP_VERSION=3
# ENV SPARK_PACKAGE=spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}
# ENV SPARK_HOME=/usr/local/spark

# # Install necessary dependencies
# RUN apt-get update && apt-get install -y \
#     openjdk-11-jdk \
#     wget \
#     curl \
#     tar \
#     && rm -rf /var/lib/apt/lists/*

# # Verify Java installation
# RUN java -version

# # Download and install Spark from the archive
# RUN wget https://archive.apache.org/dist/spark/spark-${SPARK_VERSION}/${SPARK_PACKAGE}.tgz \
#     && tar -xzf ${SPARK_PACKAGE}.tgz \
#     && mv ${SPARK_PACKAGE} /usr/local/spark \
#     && rm ${SPARK_PACKAGE}.tgz

# # Set Spark environment variables
# ENV SPARK_HOME=/usr/local/spark
# ENV PATH=$SPARK_HOME/bin:$PATH

# # Install Python dependencies
# COPY requirements.txt .
# RUN pip install --no-cache-dir -r requirements.txt

# # Copy the rest of the application code
# COPY . /app
# WORKDIR /app

# # Expose the port Flask is running on
# EXPOSE 5000

# # Define the default command to run the Flask app
# CMD ["gunicorn", "app:app", "--bind", "0.0.0.0:5000"]
