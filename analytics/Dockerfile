# Base image
FROM python:3.9-slim-buster

# Set the working directory
WORKDIR /app/analytics

# Copy the requirements file to the working directory
COPY requirements.txt .

# Install the dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy the rest of the application code to the working directory
COPY . .

# Expose port 5153
EXPOSE 5153

# Start the Flask application
CMD ["python", "app.py"]
