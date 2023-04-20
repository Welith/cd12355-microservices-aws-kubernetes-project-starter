
FROM public.ecr.aws/docker/library/python:3.11-alpine

ENV FLASK_RUN_HOST=0.0.0.0

# Set-up work directory
WORKDIR /app

# Install all required 
RUN apk update && \
    apk add \
    pcre \
    pcre-dev \
    build-base \
    gcc \
    linux-headers \
    openssl \
    libffi-dev

# Copy python requirements
COPY requirements.txt .

# Install them
RUN pip install -r requirements.txt

COPY . .

CMD python app.py