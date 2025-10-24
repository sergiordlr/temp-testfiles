  Stage 2: MachineOSBuild (MOSB) Creation and Image Build Process

  Once the MachineOSConfig is successfully created and the machine-os-builder pod is running, MCO automatically generates a MachineOSBuild resource. The MachineOSBuild resource will control an actual image build job that pulls the base CoreOS image, applies your customizations (via Containerfile), and pushes the result to your specified registry.

  In order to execute this process several auxiliary configmaps will be created in the MCO namespace.

  What to watch for:
  - Build status: Monitor the MachineOSBuild resource for conditions showing Succeeded=True or Failed=True
  - Job failures: Check if the build job in openshift-machine-config-operator namespace completes successfully
  - Image pull errors: Authentication failures when pulling the base image indicate problems with baseImagePullSecret
  - Build errors: Containerfile syntax issues, missing packages, or failed RUN commands will cause build failures
  - Image push errors: Problems pushing to the registry suggest issues with renderedImagePushSecret or registry permissions

  This is where most OCL failures occur, as it involves pulling images, executing build steps, and pushing results—all of which depend on external resources and credentials.

  This is what we see while the image is being built

```
$ oc -n openshift-machine-config-operator get machineosbuild
NAME                                     PREPARED   BUILDING   SUCCEEDED   INTERRUPTED   FAILED   AGE
infra-b1b93a87b88b18b3ad70e9fb2596b2cd   False      True       False       False         False    108s

$ oc -n openshift-machine-config-operator get job
NAME                                           STATUS     COMPLETIONS   DURATION   AGE
build-infra-b1b93a87b88b18b3ad70e9fb2596b2cd   Running    0/1           105s       105s

$ oc -n openshift-machine-config-operator get pods
NAME                                                             READY   STATUS      RESTARTS       AGE
build-infra-b1b93a87b88b18b3ad70e9fb2596b2cd-q7tsb               0/1     Init:0/1    0              2m49s
...

```

  ## Success

  We can consider this stage successful if:
  - The MachineOSBuild was created and is reporting Succeeded=True Failed=False
  - The Job will be automatically removed by the machine-os-builder pod

```
$ oc -n openshift-machine-config-operator get machineosbuild
NAME                                     PREPARED   BUILDING   SUCCEEDED   INTERRUPTED   FAILED   AGE
infra-f509ba5b2d76bcc5a113fd81de75ee99   False      True       False       False         False    27s

```

  If the MahchineOSBuild resourde is not created or is not successfull it means that there was an error.

  ## Error. Where to find the errors.

  ### The MachineOSBuild resource was not created

  The process in charge of creating the MachineOSBuild resource it the machine-os-builder pod.

  This error is not very common, but if it happens we need read the logs in this pod to find the causes:

```
  $ oc -n openshift-machine-config-operator logs machine-os-builder-b8f48488f-nsdbk
  ....
  I1017 09:42:42.524084       1 reconciler.go:634] New MachineOSBuild created: infra-f509ba5b2d76bcc5a113fd81de75ee99
  ....

```

  ### The MachineOSBuild was created but failed

  The most common cause of a failed MachineOSBuild is that th Job building the image failed to build it.

  If the MOSB resource failed the first thing we need to do is to locate the Job.


  #### The Job was not created

  The process in chage of creating/deleting this job is the machine-os-builder pod. Hence, if we cannot find the job we need to read the logs in this pod for further information

```
  $ oc -n openshift-machine-config-operator logs machine-os-builder-b8f48488f-nsdbk

```

  #### Debugging the Job

  For example, we create this MOSC

```
$ cat mosc.yaml
apiVersion: machineconfiguration.openshift.io/v1
kind: MachineOSConfig
metadata:
  name: infra
spec:
  machineConfigPool:
    name: infra
  currentImagePullSecret:
    name: current-image-pull
  imageBuilder:
    imageBuilderType: Job
  baseImagePullSecret:
    name: base-image-pull
  renderedImagePushSecret:
    name: rendered-image
  renderedImagePushSpec: "quay.io/sregidor/sregidor-os:mco_layering"
  containerFile:
      - content: |-
          RUN curl --fail -L https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64_wrong -o /usr/bin/yq && chmod +x /usr/bin/yq

$ oc create -f mosc.yaml
machineosconfig.machineconfiguration.openshift.io/infra created

```

  We can see the MachineConfigPool degraded

```
$ oc get mcp infra
NAME    CONFIG                                            UPDATED   UPDATING   DEGRADED   MACHINECOUNT   READYMACHINECOUNT   UPDATEDMACHINECOUNT   DEGRADEDMACHINECOUNT   AGE
infra   rendered-infra-6208c0db8119cfe2c9c4e42099617a43   False     False      True       1              0                   0                     0                      158m

$ oc get mcp infra -oyaml
...
  - lastTransitionTime: "2025-10-17T10:55:00Z"
    message: 'Failed to build OS image for pool infra (MachineOSBuild: infra-32ef35dea3e553071277954842edb33a):
      Failed: Build Failed'
    reason: BuildFailed
    status: "True"
    type: ImageBuildDegraded
...
```


  We can see the MOSB resource failing

```
$ oc -n openshift-machine-config-operator get machineosbuild
NAME                                     PREPARED   BUILDING   SUCCEEDED   INTERRUPTED   FAILED   AGE
infra-32ef35dea3e553071277954842edb33a   False      False      False       False         True     31m
```

  We can locate the job like this:

```
$ oc get job -l machineconfiguration.openshift.io/machine-os-config=infra
NAME                                           STATUS   COMPLETIONS   DURATION   AGE
build-infra-32ef35dea3e553071277954842edb33a   Failed   0/1           31m        31m

# These are the pods launched by the failed job

$ oc -n openshift-machine-config-operator get pods
NAME                                                             READY   STATUS       RESTARTS        AGE
build-infra-32ef35dea3e553071277954842edb33a-2jg2t               0/1     Init:Error   0               25m
build-infra-32ef35dea3e553071277954842edb33a-bzfcp               0/1     Init:Error   0               29m
build-infra-32ef35dea3e553071277954842edb33a-cndjm               0/1     Init:Error   0               32m
build-infra-32ef35dea3e553071277954842edb33a-lqlk9               0/1     Init:Error   0               22m
```

We can have a look at the failed pods logs to know the reason.

The build pods have 2 containers: image-build and create-digest-configmap. The container image-build will actually build the image and push it, and the container create-digest-configmap will create and auxiliary configmap with the right digest so that it can be read and MCO can update the MOSB and MOSC resources.

Since we are looking for errors in the build proces, we will have a look at the image-build container in the build pod

```
$ oc -n openshift-machine-config-operator logs build-infra-32ef35dea3e553071277954842edb33a-2jg2t -c image-build
...
time="2025-10-17T10:51:32Z" level=debug msg="Running &exec.Cmd{Path:\"/bin/sh\", Args:[]string{\"/bin/sh\", \"-c\", \"curl --fail -L https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64_wrong -o /usr/bin/yq && chmod +x /usr/bin/yq\"}, Env:[]string{\"HTTP_PROXY=\", \"HTTPS_PROXY=\", \"NO_PROXY=\", \"PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin\", \"HOSTNAME=0430829320a1\", \"HOME=/root\"}, Dir:\"/\", Stdin:(*os.File)(0xc0001280a0), Stdout:(*os.File)(0xc0001280a8), Stderr:(*os.File)(0xc0001280b0), ExtraFiles:[]*os.File(nil), SysProcAttr:(*syscall.SysProcAttr)(0xc00017c0c0), Process:(*os.Process)(nil), ProcessState:(*os.ProcessState)(nil), ctx:context.Context(nil), Err:error(nil), Cancel:(func() error)(nil), WaitDelay:0, childIOFiles:[]io.Closer(nil), parentIOPipes:[]io.Closer(nil), goroutine:[]func() error(nil), goroutineErr:(<-chan error)(nil), ctxResult:(<-chan exec.ctxResult)(nil), createdByStack:[]uint8(nil), lookPathErr:error(nil), cachedLookExtensions:struct { in string; out string }{in:\"\", out:\"\"}} (PATH = \"\")"
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
^M  0     0    0     0    0     0      0      0 --:--:-- --:--:-- --:--:--     0^M  0     0    0     0    0     0      0      0 --:--:-- --:--:-- --:--:--     0
^M  0     9    0     0    0     0      0      0 --:--:-- --:--:-- --:--:--     0
curl: (22) The requested URL returned error: 404
subprocess exited with status 22
subprocess exited with status 22
time="2025-10-17T10:51:32Z" level=debug msg="Error building at step {Env:[HTTP_PROXY= HTTPS_PROXY= NO_PROXY= PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin] Command:run Args:[curl --fail -L https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64_wrong -o /usr/bin/yq && chmod +x /usr/bin/yq] Flags:[] Attrs:map[] Message:RUN curl --fail -L https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64_wrong -o /usr/bin/yq && chmod +x /usr/bin/yq Heredocs:[] Original:RUN curl --fail -L https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64_wrong -o /usr/bin/yq && chmod +x /usr/bin/yq}: exit status 22"
Error: building at STEP "RUN curl --fail -L https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64_wrong -o /usr/bin/yq && chmod +x /usr/bin/yq": exit status 22
```

We can see that curl returned `curl: (22) The requested URL returned error: 404` when it tries to reach https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64_wrong. It happens because we made a typo in the URL and the actual URL should be  https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64.


Once we have detected our error, editting the MOSC resource and using the right URL in the Constainerfile section will trigger a new MOSB resource that will successfully build the image and apply the config.


In this case it was a problem in the build, but if we see that build processis not failing but nevertheless the build pod fails, we may have a look at the create-digest-configmap container to see if there was any problem creating the configmap with the digest info.

Other kind of errors can be found here, like the ones regarding the lack of permissions to pull or push the images. For example, we can see here the pod reporting that the configured secret doesn't have permissions to push the image


```
$ oc logs build-infra-5e0c7aaf3cf26e8fab9dd111bb336342-czzjb -c image-build
....
Copying blob sha256:29f46dbdbc11454d191cd70ebbd18aec36bc2afc72757d38f2ad473b6dba1c75
Copying blob sha256:d0a1fe72e3dceadb214f96787144ef31672f2b2a429a3798717d739a55a9b574
Error: pushing image "quay.io/sregidor/sregidor-os:infra-5e0c7aaf3cf26e8fab9dd111bb336342" to "docker://quay.io/sregidor/sregidor-os:infra-5e0c7aaf3cf26e8fab9dd111bb336342": writing blob: initiating layer upload to /v2/sregidor/sregidor-os/blobs/uploads/ in quay.io: unauthorized: access to the requested resource is not authorized
```

## Auxiliary Resources

In order to build the image MCO uses several auxiliary resources that are temporarily stored in the MCO namespace. They will only be present while the building process, but in case of a failure in the build process, those resources can be reached for further debugging.

Those ausiliary resources are mounted in the build pod, so that it can use them.


We find those resources like this

```
$ oc get cm -n openshift-machine-config-operator --sort-by metadata.creationTimestamp
...
additionaltrustbundle-infra-32ef35dea3e553071277954842edb33a   1      47m
etc-policy-infra-32ef35dea3e553071277954842edb33a              1      47m
mc-infra-32ef35dea3e553071277954842edb33a                      1      47m
containerfile-infra-32ef35dea3e553071277954842edb33a           1      47m
etc-registries-infra-32ef35dea3e553071277954842edb33a          1      47m


$ oc get secret -n openshift-machine-config-operator --sort-by metadata.creationTimestamp
NAME                                           TYPE                                  DATA   AGE
...
global-pull-secret-copy                        kubernetes.io/dockerconfigjson        1      48m
final-infra-32ef35dea3e553071277954842edb33a   kubernetes.io/dockerconfigjson        1      48m
base-infra-32ef35dea3e553071277954842edb33a    kubernetes.io/dockerconfigjson        1      48m
```

We can describe some of them:

- The additional trust bundle configmap additionaltrustbundle-infra-32ef35dea3e553071277954842edb33a will store the necessary bundles to use rhel packages in the Containerfile. It should be taken from a copy of the etc-pki-entitlement secret in the openshift-config-managed namespace.

- The current machine config configmap mc-infra-32ef35dea3e553071277954842edb33a will store the MachineConfig resource that needs to be applied to the nodes in this MachineConfigPool

`$ oc get cm -n openshift-machine-config-operator mc-infra-32ef35dea3e553071277954842edb33a -o jsonpath='{.data.machineconfig\.json\.gz}' | base64 -d | gunzip | jq | less`

- The container file configmap containerfile-infra-32ef35dea3e553071277954842edb33a will store the full container file used to build the image

`oc get cm -oyaml containerfile-infra-32ef35dea3e553071277954842edb33a -o jsonpath='{.data.Containerfile}'`

- Etc registries and policies configmaps (etc-registries-infra-32ef35dea3e553071277954842edb33a etc-policy-infra-32ef35dea3e553071277954842edb33a) contain the registry configuration (registries.conf) and the policies (policy.json) used in the cluster, so that they can be used too in the build process. We can check those resource if we see that we have problems with the containers registries.

```
$ oc -n openshift-machine-config-operator get cm -oyaml etc-registries-infra-32ef35dea3e553071277954842edb33a
apiVersion: v1
data:
  registries.conf: |
    unqualified-search-registries = ['registry.access.r.com', 'docker.io']
...
```

The secrets are the ones configured in the MOSC resource and contain the credentials to pull/push the necessary images

As mentioned above, if the MOSB fails, the are not removed so that we can use them for further debugging.
