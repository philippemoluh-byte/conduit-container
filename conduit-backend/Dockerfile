# Use a lightweight Python 3.5.2 slim image as the base image
FROM python:3.5.2-slim

# Define build arguments for the working directory and application port
ARG _WORKDIR=/app
ARG APP_PORT=8001

# Set environment variables to prevent Python from writing .pyc files and to enable unbuffered output
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

# Set the working directory inside the container
WORKDIR ${_WORKDIR}

# Copy all application files to the working directory in the container
COPY . ${_WORKDIR}

# Install Python dependencies from requirements.txt and make the entrypoint script executable
RUN pip install -r requirements.txt --no-cache-dir \
     && chmod +x ${_WORKDIR}/entrypoint.sh \
     && sed -i 's/\r$//g' ${_WORKDIR}/entrypoint.sh

# Expose the application port
EXPOSE ${APP_PORT}

# Set the entrypoint script to run when the container starts
ENTRYPOINT ["/app/entrypoint.sh"]