# Use an official Python runtime as a parent image
FROM python:3.11-slim

# Set the working directory in the container
WORKDIR /app

# Copy the requirements file into the container at /app
COPY requirements.txt requirements.txt

# Install any needed packages specified in requirements.txt
# Use --no-cache-dir to reduce image size
RUN pip install --no-cache-dir -r requirements.txt

# Copy the current directory contents into the container at /app
COPY . .

# Make port 8080 available to the world outside this container
EXPOSE 8080

# Define environment variable
ENV PORT 8080

# Run main.py when the container launches using Gunicorn
# Use the PORT environment variable for the bind address
CMD ["gunicorn", "--bind", ":$PORT", "--workers", "1", "--threads", "8", "--timeout", "0", "main:app"] 