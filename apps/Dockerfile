# Use the official lightweight Nginx image as a base
FROM nginx:alpine

# Remove the default Nginx welcome page
RUN rm /usr/share/nginx/html/index.html

# Copy our custom index.html file to the Nginx web root directory
COPY index.html /usr/share/nginx/html