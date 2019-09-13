Creates:
  - A nginx deployment for a pod with a init container that will write a helloworld index.hmlt in the html directory
  - A service
  - A route

The image used to generate the init pod is configurable.

Internal image:
oc process -f nginx-initpod-template.yml -p INIT_IMAGE=docker-registry.default.svc:5000/initpod/internal-alpine:int | oc create -f -

External image:
oc process -f nginx-initpod-template.yml -p INIT_IMAGE=docker.io/alpine:latest  | oc create -f -
