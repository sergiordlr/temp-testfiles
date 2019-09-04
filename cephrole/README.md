Dirty hack on the ceph workload to install a test environment using nodes directories as volumes.

How to:

1. export KUBECONFIG=....
2. ansible-playbook install_ceph.yml -e ACTION=create
