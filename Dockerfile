# Use official Node.js 18 Alpine image
FROM node:18-alpine

# Set working directory
WORKDIR /app

# Copy package.json and package-lock.json
COPY package*.json ./

# Install dependencies
RUN npm install

# Copy all app files (including logoswayatt.png and app.js)
COPY . .

# Expose port 3000 for the Express app
EXPOSE 3000

# Start the app
CMD ["node", "app.js"]
