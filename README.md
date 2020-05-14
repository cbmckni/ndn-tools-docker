# ndn-tools-docker

### Local Run

To run the container locally, first set up a volume to hold peristent data:

`docker volume create persistent-storage`

Run the image using the volume:

`docker run -it --mount source=persistent-data,target=/workspace cbmckni/ndn-tools`

### Kubernetes

Use the files and documentation in [ndn-k8s](https://github.com/cbmckni/ndn-k8s) to deploy the container to a Kubernetes cluster.


