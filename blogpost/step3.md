  Stage 3: Image Applied to Nodes


  After a successful build, the MCO will roll out the new image updating the machineconfiguration.openshift.io/desiredImage annotation in the nodes and the MachineConfigDaemon pods will apply the image.

  What to watch for:
  - Pool update status: The MachineConfigPool should show Updating=True as nodes begin updating
  - Image pull failures: Nodes may fail to download the image if currentImagePullSecret is incorrect
  - Network connectivity: Nodes must be able to reach the registry where the image is stored
  - Node degradation: Check for nodes stuck in degraded state due to failed updates
  - Reboot issues: Nodes should successfully reboot into the new OS image
  - Stalled updates: If the pool remains in Updating state too long, investigate individual node statuses

  In this final stage, issues typically relate to nodes' ability to access and apply the layered image.


  ## Success

  The MCP should report an updated status


```
AQUI EL MCP
```

  And we can check that the image is properly applied in our nodes

``
  $ oc debug -q node/ip-10-0-10-154.us-east-2.compute.internal -- chroot /host rpm-ostree status
State: idle
Deployments:
* ostree-unverified-registry:quay.io/sregidor/sregidor-os@sha256:8761d4273f3213f2f9c9b4aa9dbe33aa758f17d691f0f53d2b20f55702c9ef13
                   Digest: sha256:8761d4273f3213f2f9c9b4aa9dbe33aa758f17d691f0f53d2b20f55702c9ef13
                  Version: 9.6.20251013-1 (2025-10-17T12:09:08Z)
$ oc debug -q node/ip-10-0-10-154.us-east-2.compute.internal -- chroot /host which yq
/usr/bin/yq

$ oc debug -q node/ip-10-0-10-154.us-east-2.compute.internal -- chroot /host yq -help
Error: unknown shorthand flag: 'l' in -lp
Usage:
  yq [flags]
  yq [command]

``

  ## Error. Where to find the errors.

  At this point the debugging process is very similar to the one followed when we apply a new MachineConfig. We basically need to focus on checking the MachineConfigPool status, the information in the MachineConfigNodes resources and the logs of the machine-config-daemon pods.


  In case of error we will see the MCP degraded

```
$ oc get mcp infra
NAME    CONFIG                                            UPDATED   UPDATING   DEGRADED   MACHINECOUNT   READYMACHINECOUNT   UPDATEDMACHINECOUNT   DEGRADEDMACHINECOUNT   AGE
infra   rendered-infra-6208c0db8119cfe2c9c4e42099617a43   False     False      True       3              0                   0                     1                      3h51m

$ oc get mcp infra -oyaml
...
  - lastTransitionTime: "2025-10-17T12:23:48Z"
    message: 'Node ip-10-0-75-69.us-east-2.compute.internal is reporting: "Node ip-10-0-75-69.us-east-2.compute.internal
      upgrade failure. Failed to update OS to quay.io/sregidor/sregidor-os@sha256:8761d4273f3213f2f9c9b4aa9dbe33aa758f17d691f0f53d2b20f55702c9ef13
      after retries: timed out waiting for the condition", Node ip-10-0-75-69.us-east-2.compute.internal
      is reporting: "Failed to update OS to quay.io/sregidor/sregidor-os@sha256:8761d4273f3213f2f9c9b4aa9dbe33aa758f17d691f0f53d2b20f55702c9ef13
      after retries: timed out waiting for the condition"'
    reason: 1 nodes are reporting degraded status on sync
    status: "True"
    type: NodeDegraded
```

  And the detailed information can be found in the machine-config-daemon pod logs


```
$ oc logs -n openshift-machine-config-operator $(oc get pods -n openshift-machine-config-operator -l "k8s-app=machine-config-daemon" --field-selector "spec.nodeName=ip-10-0-75-69.us-east-2.compute.internal" -o jsonpath="{.items[0].metadata.name}") -c machine-config-daemon
...
I1017 12:26:52.042570    2750 update.go:2546] Updating OS to layered image "quay.io/sregidor/sregidor-os@sha256:8761d4273f3213f2f9c9b4aa9dbe33aa758f17d691f0f53d2b20f55702c9ef13"
I1017 12:26:52.042590    2750 image_manager_helper.go:92] Running captured: rpm-ostree --version
I1017 12:26:52.055729    2750 image_manager_helper.go:194] Linking rpm-ostree authfile to /etc/mco/internal-registry-pull-secret.json
I1017 12:26:52.055759    2750 rpm-ostree.go:183] Executing rebase to quay.io/sregidor/sregidor-os@sha256:8761d4273f3213f2f9c9b4aa9dbe33aa758f17d691f0f53d2b20f55702c9ef13
I1017 12:26:52.055764    2750 update.go:2630] Running: rpm-ostree rebase --experimental ostree-unverified-registry:quay.io/sregidor/sregidor-os@sha256:8761d4273f3213f2f9c9b4aa9dbe33aa758f17d691f0f53d2b20f55702c9ef13
Pulling manifest: ostree-unverified-registry:quay.io/sregidor/sregidor-os@sha256:8761d4273f3213f2f9c9b4aa9dbe33aa758f17d691f0f53d2b20f55702c9ef13
W1017 12:26:52.427068    2750 update.go:2591] Failed to update OS to quay.io/sregidor/sregidor-os@sha256:8761d4273f3213f2f9c9b4aa9dbe33aa758f17d691f0f53d2b20f55702c9ef13 (will retry): error running rpm-ostree rebase --experimental ostree-unverified-registry:quay.io/sregidor/sregidor-os@sha256:8761d4273f3213f2f9c9b4aa9dbe33aa758f17d691f0f53d2b20f55702c9ef13: error: Creating importer: failed to invoke method OpenImage: failed to invoke method OpenImage: reading manifest sha256:8761d4273f3213f2f9c9b4aa9dbe33aa758f17d691f0f53d2b20f55702c9ef13 in quay.io/sregidor/sregidor-os: manifest unknown
```


  It is also worth checking the information reported by the MachinConfigNode resources. Especially because in the future versions of Openshift more information reagarding the OCL process will be added to those resources in order to make the debugging process easier.

```
$ oc get machineconfignode -o wide
NAME                                        POOLNAME   DESIREDCONFIG                                      CURRENTCONFIG                                      UPDATED   AGE     UPDATEPREPARED   UPDATEEXECUTED   UPDATEPOSTACTIONCOMPLETE   UPDATECOMPLETE   RESUMED   UPDATEDFILESANDOS   CORDONEDNODE   DRAINEDNODE   REBOOTEDNODE   UNCORDONEDNODE
ip-10-0-10-154.us-east-2.compute.internal   infra      rendered-infra-6208c0db8119cfe2c9c4e42099617a43    rendered-infra-6208c0db8119cfe2c9c4e42099617a43    True      4h34m   False            False            False                      False            False     False               False          False         False          False
ip-10-0-22-152.us-east-2.compute.internal   master     rendered-master-93a022e91aa2bf815e4efed220ac97ea   rendered-master-93a022e91aa2bf815e4efed220ac97ea   True      4h44m   False            False            False                      False            False     False               False          False         False          False
ip-10-0-41-78.us-east-2.compute.internal    infra      rendered-infra-6208c0db8119cfe2c9c4e42099617a43    rendered-infra-6208c0db8119cfe2c9c4e42099617a43    True      4h34m   False            False            False                      False            False     False               False          False         False          False
ip-10-0-60-66.us-east-2.compute.internal    master     rendered-master-93a022e91aa2bf815e4efed220ac97ea   rendered-master-93a022e91aa2bf815e4efed220ac97ea   True      4h44m   False            False            False                      False            False     False               False          False         False          False
ip-10-0-65-176.us-east-2.compute.internal   master     rendered-master-93a022e91aa2bf815e4efed220ac97ea   rendered-master-93a022e91aa2bf815e4efed220ac97ea   True      4h44m   False            False            False                      False            False     False               False          False         False          False
ip-10-0-75-69.us-east-2.compute.internal    infra      rendered-infra-6208c0db8119cfe2c9c4e42099617a43    rendered-worker-6208c0db8119cfe2c9c4e42099617a43   False     4h40m   True             Unknown          False                      False            False     Unknown             True           True          False          False



$ oc get machineconfignode ip-10-0-75-69.us-east-2.compute.internal -oyaml
...
  - lastTransitionTime: "2025-10-17T12:22:13Z"
    message: 'Node ip-10-0-75-69.us-east-2.compute.internal upgrade failure. Failed
      to update OS to quay.io/sregidor/sregidor-os@sha256:8761d4273f3213f2f9c9b4aa9dbe33aa758f17d691f0f53d2b20f55702c9ef13
      after retries: timed out waiting for the condition'
    reason: NodeDegraded
    status: "True"
```
