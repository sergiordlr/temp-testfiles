# MCO Claude memory

In the CLAUDE.md file we try to describe some of the operations that MCO can do, so that Claude can understand them and use them.

Just copy the CLAUDE.md file to your current repo, or copy it to ~/.claude/CLAUDE.md

## Prepare cluster

Apart from the normal operations we can instruct Claude to "prepare the cluster". A prepared cluster is a cluster with only 2 workers (instead of 3) and with a pull secret containing the credentials in the "credentials.json" file.

In the credentials.json file should be included the credentials to access the external registry that we use to store our osImages.

```
 podman login quay.io/myrepo/mylayeredimage --authfile credentials.json
```

## Prompt examples

- Create a new custom pool with 1 node
- Create a new custom pool named "infra" with 1 node and enable OCL in it
- Disable OCL in the infra pool
- Remove the infra pool
- Create a new password in the worker pool
- Configure kernel argument "arg=1" in worker pool
- Configure realtime kernel type in the worker pool
- Configure a new osImage in the worker pool with the cowsay package
- Enable OCL in the worker pool with a container installing the yq binary
....

# OpenShift Machine Config Operator (MCO) Operations. (AI generated summary)

Based on CLAUDE.md, here are the operations I can perform:

## Cluster Operations
- Prepare a cluster for testing (scale to 2 worker nodes, manage credentials, wait for updates)
- Access OpenShift clusters using `oc` binary

## On Cluster Layering (OCL)
- Configure OCL with external registry (create MachineOSConfig with pull/push secrets)
- Configure OCL with internal registry (create MachineOSConfig using builder SA)
- Add custom Containerfiles to MachineOSConfig
- Verify MachineOSBuild resources reach "Succeeded" status
- Disable OCL by deleting MachineOSConfig

## Off Cluster Layering
- Get base image using `oc adm release info --image-for "rhel-coreos"`
- Create custom osImages using Containerfiles
- Get image sha256 using `skopeo inspect`

## MachineConfigPool Management
- Create custom MachineConfigPools
- Add nodes to pools by adding labels
- Remove nodes from pools by removing labels
- Safely delete custom pools (migrate nodes first)

## MachineConfig Operations
- Add files to nodes (with base64-encoded content and permissions)
- Configure kernel arguments
- Configure FIPS settings (installation-time only)
- Configure custom osImage URLs (sha256 only, no tags)
- Configure kernel types (default, realtime, 64k-pages)
- Configure user passwords (using openssl-generated hashes)
- Configure SSH keys for users

## Image and Container Management
- Create CoreOS-compatible Containerfiles
- Add CentOS and EPEL yum repos when needed
- Manage external registry credentials via credentials.json

## Recovery Operations
- Recover degraded MachinConfigPools by removing offending MCs
- Sync node annotations (desiredConfig = currentConfig)
