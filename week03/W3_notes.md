# Running Python server

```bash
python server.py
```

## Build the Docker image:

```bash
docker build  -t mst300fall24 .
```

## Run the Docker Container

```bash
docker run -p 8000:8000 mst300fall24
```


## Push the Docker image to the Docker hub

```bash
docker login
docker tag mst300fall24 maziar/mst300fall24:v0.1
docker push maziar/mst300fall24:v0.1
docker run -p 8000:8000 maziar/mst300fall24
```