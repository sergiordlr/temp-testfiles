  Stage 1: MachineOSConfig (MOSC) Creation 

  The process begins when you create a MachineOSConfig resource targeting a specific MachineConfigPool. This resource acts as the blueprint, defining how your custom OS image should be built and where it should be stored.

  What to watch for:
  - Validation errors: The resource may fail to create if required fields are missing or incorrectly configured
  - Secret references: Ensure all referenced pull/push secrets exist in the correct namespace (openshift-machine-config-operator)
  - Registry specifications: Verify that renderedImagePushSpec points to a valid, accessible registry location

  At this stage, issues are typically configuration errors that prevent the resource from being created or accepted by the cluster.

  ## Success

  If the MOSC resrouce was successfully created, we should see that the machine-os-builder pod is healthy and running in the MCO namespace.

```
$ oc get pods -n openshift-machine-config-operator -l k8s-app=machine-os-builder
NAME                                 READY   STATUS    RESTARTS   AGE
machine-os-builder-b8f48488f-lth94   1/1     Running   0          44s
```

  If we can see this pod, we can focus on debugging the next step, the step the builds the image.

  If we can't see this pod it means that some errors have occurred.

  ## Errror. Where to find the errors.

  If we are using a forbidden value for any of the fields in MachineOSConfgig we should see it printed in the create command:

We can see that we are using "spec.imageBuilder.imageBuilderType" = "job" instead of the mandatory value "Job"
```
# Bad mosc resource
$ cat ./mosc.yaml 
apiVersion: machineconfiguration.openshift.io/v1
kind: MachineOSConfig
metadata:
  name: worker
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

$ oc create -f ./mosc.yaml
The MachineOSConfig "worker" is invalid: 
* spec.imageBuilder.imageBuilderType: Unsupported value: "job": supported values: "Job"
```

Another example:

```
$ oc create -f ./mosc.yaml
The MachineOSConfig "worker" is invalid: <nil>: Invalid value: "object": MachineOSConfig name must match the referenced MachineConfigPool name; can only have one MachineOSConfig per MachineConfigPool
```


  If the values we are using are not forbidden, but nevertheless are causing problems, the information to detect those problems can be found in the machine-config-operator pod, in the triggered events, and in the machine-config ClusterOoperator. The most dedailed information can be found in the machine-config-operator pod. 

For example:

```
# We forgot to create the secrets
$ cat ./mosc.yaml 
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

# The resource can be created
$ oc create -f ./mosc.yaml
machineosconfig.machineconfiguration.openshift.io/infra created

# The builder pod is not created
$ oc get pods -n openshift-machine-config-operator |grep build

# We can find the error in the machine-config-operator pod
$ oc logs -n openshift-machine-config-operator machine-config-operator-7498f4576b-h5vzj 
...
E1017 08:56:53.431756       1 operator.go:467] "Unhandled Error" err="could not update Machine OS Builder deployment: could not validate renderedImagePushSecret \"rendered-image\" for MachineOSConfig infra: secret rendered-image from infra is not found. Did you use the right secret name?"
...

# And we can that there are events reporting this error too
$ oc get events  -n openshift-machine-config-operator --sort-by metadata.creationTimestamp  |tail -3
34s         Warning   OperatorDegraded: MachineOSBuilderFailed   /machine-config                                                      Failed to resync 4.20.0-0-2025-10-16-080835-test-ci-ln-bfn63jk-latest because: could not update Machine OS Builder deployment: could not validate renderedImagePushSecret "rendered-image" for MachineOSConfig infra: secret rendered-image from infra is not found. Did you use the right secret name?
11s         Warning   OperatorDegraded: MachineOSBuilderFailed   /machine-config                                                      Failed to resync 4.20.0-0-2025-10-16-080835-test-ci-ln-bfn63jk-latest because: could not update Machine OS Builder deployment: could not validate baseImagePullSecret "base-image-pull" for MachineOSConfig infra: secret base-image-pull from infra is not found. Did you use the right secret name?
96s         Normal    ConfigMapUpdated                           deployment/machine-config-operator                                   Updated ConfigMap/kube-rbac-proxy -n openshift-machine-config-operator:...

# We can check the machine-config ClusterOperator too
$ oc get co machine-config
NAME             VERSION                                                AVAILABLE   PROGRESSING   DEGRADED   SINCE   MESSAGE
machine-config   4.20.0-0-2025-10-16-080835-test-ci-ln-bfn63jk-latest   True        False         True       76m     Failed to resync 4.20.0-0-2025-10-16-080835-test-ci-ln-bfn63jk-latest because: could not update Machine OS Builder deployment: could not validate renderedImagePushSecret "rendered-image" for MachineOSConfig infra: secret rendered-image from infra is not found. Did you use the right secret name?

```

