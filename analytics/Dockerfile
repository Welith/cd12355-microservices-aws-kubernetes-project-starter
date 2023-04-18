# Base image
FROM public.ecr.aws/amazonlinux/amazonlinux:2

RUN yum install -y amazon-linux-extras

# Install Python 3.9 and other required packages
RUN amazon-linux-extras install python3.9 && \
    yum install -y python3.9-libs python3.9-devel python3.9-pip

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
