# Use the JavaScript/Node.js Alpine base (includes git, npm, etc.)
FROM mcr.microsoft.com/devcontainers/javascript-node:18-alpine

# Install Docker CLI
RUN apk update \
    && apk add --no-cache docker-cli \
    && rm -rf /var/cache/apk/*