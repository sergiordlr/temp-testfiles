Mirrors downstream images to local ocp3 cluster docker registry. If operator.yml and controller-3.yml files are provided, they are installed too.

1. Log in to ocp3 with admin user or 'export KUBECONFIG=.../admin.kubeconfig.file'
2. If you want to install non-olm operator and controller, copy operator.yml and contrller-3.yml files to the current directory.
    https://github.com/fusor/mig-operator/tree/master/deploy/test-helpers/non-olm/v1.0.0
3. Run this command:

    ansible-playbook mig_install_downstream_3x.yml -K

You can mirror the stage images by using the stage variables

    ansible-playbook mig_install_downstream_3x.yml -K -e @stage_vars.yml

Do not forget the -K, since there are operations that need sudo. -K will promt you to introduce your sudo password.

This automation is only valid for 3.x ocp. For 4.x ocp use the mig-operator instructions in https://github.com/fusor/mig-operator/tree/master/deploy/test-helpers
