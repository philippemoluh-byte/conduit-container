# Use Node.js 20 Alpine image as the base image for the build stage
FROM node:20-alpine AS builder

# Set the working directory inside the container
WORKDIR /app

# Copy package files to the container
COPY package*.json  ./

# Install dependencies using npm
RUN npm ci

# Copy the rest of the application files to the container
COPY . .

# Build the Angular application for production
RUN npm run build -- --configuration production

# Use Nginx Alpine image as the base image for the production stage
FROM nginx:1.25-alpine AS production

# Define the port to expose for the application
ARG HOST_PORT=8282

# Copy the built application from the builder stage to the Nginx directory
COPY --from=builder /app/dist/angular-conduit /opt/app-dist

# Copy the Nginx configuration file to the container
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Remove Windows-style line endings and make the entrypoint script executable
RUN sed -i 's/\r$//' /etc/nginx/conf.d/default.conf

# Expose the application port
EXPOSE ${HOST_PORT}

# Set the entrypoint command directly in the Dockerfile
CMD ["nginx", "-g", "daemon off;"]
