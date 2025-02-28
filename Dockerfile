# Step 1: Base image
FROM python:3.10-slim

# Set environment variables
ENV PYTHONUNBUFFERED=1
# ENV JAVA_HOME="/usr/lib/jvm/java-11-openjdk-amd64"
ENV JAVA_HOME="/usr/lib/jvm/java-17-openjdk-amd64"
ENV SPARK_VERSION="3.5.2"
ENV HADOOP_VERSION="3"
ENV SPARK_PACKAGE="spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}"
# ENV SPARK_PACKAGE="spark-3.5.2-bin-hadoop3"
ENV SPARK_HOME="/usr/local/spark"
ENV PYTHON_PATH="/opt/conda/bin/python3"
# ENV PATH="/usr/bin:/opt/conda/bin:/usr/local/spark/bin:/usr/lib/jvm/java-11-openjdk-amd64/bin:$PATH"
ENV PATH="/usr/bin:/opt/conda/bin:/usr/local/spark/bin:/usr/lib/jvm/java-17-openjdk-amd64/bin:$PATH"

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
    bash \
    && ln -sf /bin/bash /bin/sh \
    && rm -rf /var/lib/apt/lists/*

# Debugging step: Verify that bash is correctly installed and linked
RUN which bash && bash --version && chmod +x /bin/bash
RUN java -version

# Step 3: Install Miniforge (to manage Python packages and Jupyter)
RUN wget https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Linux-x86_64.sh -O Miniforge3.sh && \
    bash Miniforge3.sh -b -p /opt/conda && \
    rm Miniforge3.sh

# Step 4: Download and install Spark
RUN wget https://archive.apache.org/dist/spark/spark-${SPARK_VERSION}/${SPARK_PACKAGE}.tgz \
    && tar -xzf ${SPARK_PACKAGE}.tgz \
    && mv ${SPARK_PACKAGE} /usr/local/spark \
    && rm ${SPARK_PACKAGE}.tgz

# RUN wget https://archive.apache.org/dist/spark/spark-3.5.2/spark-3.5.2-bin-hadoop3.tgz \
#     && tar -xzf spark-3.5.2-bin-hadoop3.tgz \
#     && mv spark-3.5.2-bin-hadoop3 /usr/local/spark \
#     && rm spark-3.5.2-bin-hadoop3.tgz

# Step 5: Install MongoDB, Jupyter, and other dependencies
RUN conda install -y jupyter && \
    pip install pymongo gunicorn Flask geemap requests

# Step 6: Install Python dependencies from requirements.txt
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Step 7: Copy the app files
WORKDIR /app
COPY . .

# Step 8: Expose the port and run the app
EXPOSE 5000
# CMD ["gunicorn", "-w", "4", "-b", "0.0.0.0:5000", "app:app"]
CMD ["gunicorn", "-w", "4", "-b", "0.0.0.0:5000", "--timeout", "1200", "app:app"]
