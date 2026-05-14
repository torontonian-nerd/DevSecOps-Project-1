# Use official Node.js version 20 image based on Alpine Linux.
# Alpine is lightweight, so the final image is smaller.
FROM node:20-alpine

# Set working directory for the frontend/client application.
# All following commands will run from this path until WORKDIR changes.
WORKDIR /usr/src/app/client

# Copy only client package files first.
# This helps Docker cache npm install unless package.json/package-lock.json changes.
COPY client/package*.json ./

# Install client dependencies.
# Required to build the frontend application.
RUN npm install

# Copy the full client source code into the image.
COPY client/ ./

# Build the client app.
# Usually creates a production-ready build folder or public assets.
RUN npm run build

# Change working directory to the backend/server application.
WORKDIR /usr/src/app/server

# Copy only server package files first.
# Again, this improves Docker layer caching for dependencies.
COPY server/package*.json ./

# Install only production dependencies for the server.
# --omit=dev skips devDependencies to reduce image size.
RUN npm install --omit=dev

# Copy the full server source code into the image.
COPY server/ ./

# Create a public folder inside the server directory.
# Then copy built/static frontend files from the client into the server public folder.
# This allows the backend server to serve the frontend files.
RUN mkdir -p ./public && cp -R /usr/src/app/client/public/* ./public/

# Set environment to production.
# Many Node.js apps use this to enable production behavior.
ENV NODE_ENV=production

# Create a system group and system user for running the app.
# This avoids running the container as root, which is better for security.
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

# Change ownership of the app files to the non-root user.
# This ensures appuser can read/run the application files.
RUN chown -R appuser:appgroup /usr/src/app

# Switch from root to the non-root user.
# All commands after this, including CMD, run as appuser.
USER appuser

# Document that the container listens on port 5000.
# This does not publish the port by itself; docker run -p is still needed.
EXPOSE 5000

# Start the server application.
# This runs "npm start" from the current WORKDIR: /usr/src/app/server.
CMD ["npm", "start"]