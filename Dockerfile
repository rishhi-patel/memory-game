# Build & Export Next.js App to Static Files
FROM node:22-alpine AS builder

#working directory
WORKDIR /app

# Copy and Install dependencies

COPY . .

RUN npm install --force

RUN npm run build

#Serve Static Files with Nginx
FROM nginx:stable-alpine

#Remove default Nginx static assets
RUN rm -rf /usr/share/nginx/html/*

#Copy exported static site from builder
COPY --from=builder /app/out/ /usr/share/nginx/html/

#Expose port 80
EXPOSE 80

#Start Nginx in the foreground
CMD ["nginx", "-g", "daemon off;"]