# Dockerfile
FROM node:18-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY . .
# if you have build step uncomment
# RUN npm run build

FROM node:18-alpine AS runtime
WORKDIR /app
COPY --from=builder /app . 
ENV NODE_ENV=production
EXPOSE 3000
CMD ["node", "index.js"]
