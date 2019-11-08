Mirrors downstream images to local ocp3 cluster docker registry. If operator.yml and controller-3.yml files are provided, they are installed too.

1. Log in to ocp3 with admin user or 'export KUBECONFIG=.../admin.kubeconfig.file'

2. Run this command:

    ansible-playbook mig_install_downstream_3x.yml -K

The playbook will get the operator.yml and controller-3.yml files from the operator image with this command

  podman cp $(podman create $MIRRORED_OPERATOR_IMAGE ):/operator.yml ./
  podman cp $(podman create $MIRRORED_OPERATOR_IMAGE ):/controller-3.yml ./

The operator image wil always be deleted before getting the controller and the pod. -e foce_podan=false parameter will avoid this behavior.

If the operator.yml and the controller-3.yml files exist and force_podman=false, it will use the those files instead of downloading them from the operator image.


You can mirror the stage images by using the stage variables

    ansible-playbook mig_install_downstream_3x.yml -e @stage_vars.yml

This automation is only valid for 3.x ocp. For 4.x ocp use the mig-operator instructions in https://github.com/fusor/mig-operator/tree/master/deploy/test-helpers
