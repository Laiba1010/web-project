# Use an official Nginx runtime as a parent image
FROM nginx:alpine

# Copy the static website files to the container
COPY . /usr/share/nginx/html

# Expose port 80 to the Docker host
EXPOSE 80

# Start Nginx and keep the process running
CMD ["nginx", "-g", "daemon off;"]