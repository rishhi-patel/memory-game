Application Containerization Steps:

For this assignment, I containerized a static Next.js application using Docker. First, I ensured the application built successfully locally with npm run build, which generates static files in the /out directory. I created a multi-stage Dockerfile to optimize image size and separate the build process from the final runtime environment.

In the first stage, I used node:22-alpine as the base image, installed dependencies using npm install --force, and built the app. In the second stage, I used the nginx:stable-alpine image to serve the static output. The compiled contents from /app/out/ were copied to the default nginx folder /usr/share/nginx/html/.

Volumes and Bind Mounts:

Although persistent storage is not critical for a static site, I used a bind mount during development to reflect local file changes without rebuilding the image every time. This was done using the docker run -v option (e.g., -v $(pwd)/out:/usr/share/nginx/html) to map the local build output to the nginx content folder. This helped test frontend updates quickly during development.

Challenges and Resolutions:

One challenge was ensuring the build output was compatible with nginx’s static file serving structure. I initially used the Next.js server directly but switched to npm run build and next export to generate a static version. Another challenge was minimizing image size and avoiding unnecessary files, which I addressed by using a multi-stage build and .dockerignore to exclude node_modules.

## important command

Build the Docker image:

```bash
docker build -t next-static-site:v1.0 .
```

Run the container:

```bash
docker run -d -p 8080:80 next-static-site:v1.0
```

The app will be accessible at [http://localhost:8080](http://localhost:8080).
