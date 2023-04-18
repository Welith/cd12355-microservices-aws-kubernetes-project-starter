# Base image
FROM amazonlinux:2

# Install required packages
RUN amazon-linux-extras install epel -y && \
    yum update -y && \
    yum install -y python3-pip python3.9 python3.9-libs python3.9-devel && \
    alternatives --install /usr/bin/python3 python3 /usr/bin/python3.6 10 && \
    alternatives --install /usr/bin/python3 python3 /usr/bin/python3.9 20 && \
    alternatives --set python3 /usr/bin/python3.9 && \
    yum clean all

# Set the working directory
WORKDIR /app

# Copy the requirements file to the working directory
COPY analytics/requirements.txt .

# Install the dependencies
RUN pip3 install --no-cache-dir -r requirements.txt

# Copy the rest of the application code to the working directory
COPY analytics/. .


# Expose port 5153
EXPOSE 5153

ENV DB_USER=""
ENV DB_PASSWORD=""

# Start the Flask application
CMD ["python3", "app.py"]
