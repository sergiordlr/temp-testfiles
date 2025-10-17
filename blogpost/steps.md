  Understanding the On Cluster Layering Process

  When you enable On Cluster Layering (OCL) in OpenShift, the workflow consists of three stages. Each stage has distinct failure points. The stages are: MachineOSConfig creation, MachineOSBuild creation and execution, the new image is applied to the nodes.

  Stage 1: MachineOSConfig Creation

  The process begins when you create a MachineOSConfig resource targeting a specific MachineConfigPool. This resource acts as the blueprint, defining how your custom OS image should be built and where it should be stored.

  What to watch for:
  - Validation errors: The resource may fail to create if required fields are missing or incorrectly configured
  - Secret references: Ensure all referenced pull/push secrets exist in the correct namespace (openshift-machine-config-operator)
  - Registry specifications: Verify that renderedImagePushSpec points to a valid, accessible registry location

  At this stage, issues are typically configuration errors that prevent the resource from being created or accepted by the cluster.





  Stage 2: MachineOSBuild Creation and Execution

  Once the MachineOSConfig is successfully created, the Machine Config Operator automatically generates a MachineOSBuild resource. This triggers an actual image build job that pulls the base CoreOS image, applies your customizations
  (via Containerfile), and pushes the result to your specified registry.

  What to watch for:
  - Build status: Monitor the MachineOSBuild resource for conditions showing Succeeded=True or Failed=True
  - Job failures: Check if the build job in openshift-machine-config-operator namespace completes successfully
  - Image pull errors: Authentication failures when pulling the base image indicate problems with baseImagePullSecret
  - Build errors: Containerfile syntax issues, missing packages, or failed RUN commands will cause build failures
  - Image push errors: Problems pushing to the registry suggest issues with renderedImagePushSecret or registry permissions
  - Timeout issues: Large builds may exceed default timeout values

  This is where most OCL failures occur, as it involves pulling images, executing build steps, and pushing results—all of which depend on external resources and credentials.

  Stage 3: Image Applied to Nodes


# ESTO ES FALSO, NO ACTUALIZA LA OS IMAGE URL, SINO LA ANOTACIÓN

  After a successful build, the MCO updates the MachineConfig with the new OS image URL, triggering the MachineConfigPool to roll out the custom image across all nodes in the pool. Each node downloads the layered image and reboots to
  apply it.

  What to watch for:
  - Pool update status: The MachineConfigPool should show Updating=True as nodes begin updating
  - Image pull failures: Nodes may fail to download the image if currentImagePullSecret is incorrect
  - Network connectivity: Nodes must be able to reach the registry where the image is stored
  - Node degradation: Check for nodes stuck in degraded state due to failed updates
  - Reboot issues: Nodes should successfully reboot into the new OS image
  - Stalled updates: If the pool remains in Updating state too long, investigate individual node statuses

  In this final stage, issues typically relate to nodes' ability to access and apply the layered image.

  ---
  In the following sections, we'll dive deep into each of these stages, showing you exactly which resources to check, what logs to examine, and how to diagnose and resolve common problems at every step of the OCL workflow.

