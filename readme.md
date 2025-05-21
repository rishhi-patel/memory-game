## Running the App with Docker

Build the Docker image:

```bash
docker build -t my-next-static:latest .
```

Run the container:

```bash
docker run -d -p 8080:80 my-next-static:latest
```

The app will be accessible at [http://localhost:8080](http://localhost:8080).
