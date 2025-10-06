Whenever we talk about a cluster we talk about an openshift cluster.

Whenever we talk about the "pull-secret" we talk about the "pull-secret" stored in the "openshift-config" namespace in the cluster

Openshift clusters accessed using the "oc" binary. The kubeconfig file will be already configured via env var, so no need to do anything to login to the cluster.


If no image is specified use: quay.io/your-external-registry/here

IMPORTANT: The images will be coreOS, so we need to take that into account when creating the Containerfile. We need to apply all the restrictions/special cases that apply to coreOS.

IMPORTANT: Base image have no yum repo configured. If you need to install a package in a Containerfile and no repo is specified, add the stream centos "bases" and "appstream" yum repos and the epel repo in the Containerfile. Explicitly notify that you are going to use this repos to the user asking for the image.

IMPORTANT: Create the temporary files in a tmp dir in the current directory. Do NOT use the /tmp directory.

# External image registry

The docker config.json file to access the external registry is  "credentials.json"

Do not extract the user and password from the file to use "podman login", use the file directly when the interaction is with the registry.

If credentials.json file does not exist ignore any reference to it and do not use it at all. Consider that the default credentials are enough in the local machine and in the cluster.

IMPORTANT: Do never print those credentials on the screen

# Prepare a cluster for testing
Steps to prepare a cluster for testing
- if the cluster has more than 2 worker nodes, scale the machinesets so that the cluster has 2 worker nodes only.
- check if the credentials in file credentials.json are present in the pull-secret secret in the openshift-config namespace, if and only if they are not present add them to the secret.
- if the those credentials were added to the pull-secret, check that the pools start updating.
- wait for all the MachineConfigPools to be updated.

Do not use machineset .status.availableReplicas to count existing nodes. Use the nodes directly.

# Configuring On Cluster Layering mode (OCL) in a MachineConfigPool (MCP)

OCL can be configured with internal registry or external registry

##  Using external registry

We need to create a MachineOSConfig resource so that:
- its name has to be the same name as the MCP
- the currentImagePullSecret.name value has to be the name of a copy of the pull-secret secret in the openshift-machine-config-operator namespace
- the baseImagePullSecret.name value has to be the name of a copy of the pull-secret secret in the openshift-machine-config-operator namespace
- the renderedImagePushSecret.name value has to be the name of a copy of the pull-secret secret in the openshift-machine-config-operator namespace
- renderedImagePushSpec  and imageBuilderType has always the same value


MachineOSConfig example for the "worker" pool:

```
apiVersion: machineconfiguration.openshift.io/v1
kind: MachineOSConfig
metadata:
  name: worker
spec:
  machineConfigPool:
    name: worker
  currentImagePullSecret:
    name: <NAME-OF-THE-SECRET-IN-MCO-COPIED-FROM-PULL-SECRET>
  imageBuilder:
    imageBuilderType: Job
  baseImagePullSecret:
    name: <NAME-OF-THE-SECRET-IN-MCO-COPIED-FROM-PULL-SECRET>
  renderedImagePushSecret:
    name: <NAME-OF-THE-SECRET-IN-MCO-COPIED-FROM-PULL-SECRET>
  renderedImagePushSpec: "quay.io/user/example:mytag"
```

##  Using internal registry

We need to create a MachineOSConfig resource so that:
- its name has to be the same name as the MCP
- the baseImagePullSecret.name value has to be the name of a copy of the pull-secret secret in the openshift-machine-config-operator namespace
- the renderedImagePushSecret.name is the name of the secret linked to the ServiceAccount with name "builder" in the openshift-machine-config-operator namespace
- renderedImagePushSpec  and imageBuilderType has always the same value
- renderedImagePushSpec  and imageBuilderType has always the same value

```
apiVersion: machineconfiguration.openshift.io/v1
kind: MachineOSConfig
metadata:
  name: worker
spec:
  machineConfigPool:
    name: worker
  imageBuilder:
    imageBuilderType: Job
  baseImagePullSecret:
    name: <NAME-OF-THE-SECRET-IN-MCO-COPIED-FROM-PULL-SECRET>
  renderedImagePushSecret:
    name: <NAME OF THE SECRET LINKED TO THE "builder" SA IN MCO NAMESPACE>
  renderedImagePushSpec: "image-registry.openshift-image-registry.svc:5000/openshift-machine-config-operator/ocb-image:latest"
```


## Configuring custom Containerfile in a MachineOSConfig

We can configure a custom Containerfile in a MachineOSConfig like this:

ContainerfileArch

```
spec:
  containerFile:
      - containerfileArch: NoArch   # Architecture. Optional. The Only supported values are "ARM64", "AMD64", "PPC64LE", "S390X", "NoArch"
        content: |-    # The content of the Containerfile
          RUN touch /etc/pre-upgrade.test
```

The "FROM" section of the container file is not added, since MCO will use the right base image for the Containerfile

## Verifications after creating the MachineOSConfig resource

A new MachineOSBuild resource will automatically be created after we create the MachineOSConfig resource. We need to wait until this MachineOSBuild reports  a "Succeeded" true status.

Once the MachineOSBuild succeeds we need to wait until the MCP is updated and upgraded.

## Disable OCL

In order to disable OCL in a MCP we need to delete the MachineOSConfig resource for this pool.

After deleting the MachineOSConfig resource we need to wait for the pool to start updating, and the to finish the update.

# Off Cluster Layering. Create a new base osImage

We can create new container images that can be used in the cluster as osImages

When we want to create a new osImage we execute this command to get the container base image:

```
oc adm release info --image-for "rhel-coreos"
```

Then we use this image as the base image in a Containerfile to generate a new osImage

The final image has to use the sha256 instead of the tag. When you get the sha256 value of an image, use `skopeo inspect`

# Custom MachineConfigPools

## Creating a new MachineConfigPool

We can create new custom machineconfigpools by creating a MachineConfigPool resource

This is an example of custom MCP named "infra"

```
apiVersion: machineconfiguration.openshift.io/v1
kind: MachineConfigPool
metadata:
  name: infra
spec:
  machineConfigSelector:
    matchExpressions:
      - {key: machineconfiguration.openshift.io/role, operator: In, values: [worker,infra]}
  nodeSelector:
    matchLabels:
      node-role.kubernetes.io/infra: ""
```

In order to add new nodes to the new infra MCP in the example, we need to add the label matching the matchLabels field of the pool to the node that we want to add to the pool. In the case of the "infra" example provided above it would be "node-role.kubernetes.io/infra".

In order to remove the node from the pool, we need to remove that label.

## Removing the custom pools

Important: Pools "master" and "worker" should NEVER  be deleted. 

When we need to remove a custom MCP, we always need to check if the pool has nodes. If that's the case, all nodes need to be removed from the MCP before removing it.

After removing the nodes from the custom pool, and before removing the custom pool, we need to check that the nodes were correctly added to the worker pool and that the worker pool is reporting an "Updated" status. Only after checking that we can remove the custom pool.

# MachineConfig (MC)

MachineConfigs are used to configure the nodes in the MachineWorkerPools

## Add a new file

A MC can be used to add a new file to the nodes in a MCP.

This is an example to configure a file located in /etc/test-file-85073.test with mode 644 (decimal 420) in the worker pool:

```
apiVersion: machineconfiguration.openshift.io/v1
kind: MachineConfig
metadata:
  labels:
    machineconfiguration.openshift.io/role: worker #  here we define the pool where it will be applied
  name: mc-example
spec:
  config:
    ignition:
      version: 3.1.0
    storage:
      files:
      - contents:
          source: data:text/plain;charset=utf-8;base64,<BASE64 ENCODED CONTENT>
        mode: 420 # decimal representation of octal 644 permissions
        path: /etc/test-file-85073.test
```

Where contents.source contains the base64 encoded content of the file in the way it is represented in the example

Where mode is the decimal representation of the octal permissions for the file. This is optional.

Where path is the path where the file will be placed in the nodes

## Configure kernel arguments

A MC can be used to configure the kernel arguments in the nodes in a MCP

To do that we need to create a MC with this spec

```
spec:
  kernelArguments:
  - KernelArg1
  - KernelArg2
```

Being KernelArg1, KernelArg2, KernelArg3.... the kernel arguments that we want to configure in the nodes

## Configure fips

A MC can be used to configure if the nodes in a pool are using fips or not.

IMPORTANT: fips can only be configured at installation time, so it cannot be reconfigured once the cluster is up and running

The fips configuration is done like in this example:

```
spec:
  fips: false # This is the fips value
```
## Configure OSImage. Off Cluster Layering

A MC can be used to configure a new osImage for the nodes in a pool.

It is done like in this example

```
spec:
  osImageURL: quay.io/image/used/as/osimage@sha25633af909a38fa2ab31db86e6edf1191f2033de6971e10f8249fb # This is the osImage used in the cluster
```

Extremely Important: The image always has to use the ONLY @sha256 name and NOT the tag. Tag and sha256 at the same time is not supported. Values like "quay.io/user/mylayer:cowsay-osimage@sha256:60eab74f607f157d9557d9fd3a0231f1a9bd05a7f67aa210cf7002790a1a4379" are not allowed. There should be no reference to tag AT ALL.

This value is only taken into account if the pool is not configured with OCL. If the pool is configured to use OCL, then this value will be ignored.


## Configure kernel type

A MC can be used to configure the kernel installed in the nodes in a pool.

It is done like in this example:


```
spec:
  kernelType: realtime # Kernel type to be used
```

The supported values for kernel type are "realtime", "64k-pages" and "default"

64k-pages kernel type can only be used in ARM clusters

## Configure a password

A MC can be used to configure a password for a user in the nodes in a pool.

It is done like in this example:


```
spec:
  config:
    ignition:
      version: 3.2.0
    passwd:
      users:
      - name: core # User name that will use the password
        passwordHash: "$6$uim4Ldknioeinfas,K$QJUwg.4lAyU4egsM7FNaNlSbuI6JfQCRufb99QuFasldkfhkbkukjb.0veXWN1HDqO.bxasdfmnhWYI1" # password's sha
```

If no user is specified, use the "core" user.

To generate the password's hash we need to use this command:

```
openssl passwd -6 $USED_PASSWORD
```

## Configure a ssh key

A MC can be used to configure ssh keys for a user in the nodes in a pool.

It is done like in this example:

```
spec:
  config:
    ignition:
      version: 3.2.0
    passwd:
      users:
      - name: core # User name that will use the ssh key
        sshAuthorizedKeys:
        - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCWkwurd8TNAi+D7ffvyDdhGBSQtJx3/Yasdfaoinlkajhsdpfiu9832kj/GGQDgTJ17h3C9TEArI8ZqILnyydeY56DL+ELN3dtGBVof/N2qtW0+SmEnd1Mi7Qy5Tx4e/GVmB3NgX9szwNOVXhebzgBsXc9x+RtCVLPLC8J+qqSdTUZ0UfJsh2ptlQLGHmmTpF//QlJ1tngvAFeCOxJUhrLAa37P9MtFsiNk31EfKyBk3eIdZljTERmqFaoJCohsFFEdO7tVgU6p5NwniAyBGZVjZBzjELoI1aZ+/g9yReIScxl1R6PWqEzcU6lGo2hInnb6nuZFGb+90D example@rkey.com # public ssh key that will be configured in the nodes

```

If no user is specified, use the "core" user.

If no public key is provided generate a ssh key pair and use the public key in the MC


# Degradation recovery attempt

When a MCP is degraded, in order to recover the cluster we need to:
- Remove the offending MC
- Configure the node being degraded so that "machineconfiguration.openshift.io/desiredConfig" annotation has the same value as  "machineconfiguration.openshift.io/currentConfig"
- Wait for the MCP to stop being degraded after reconfiguring the degraded nodes' annotations