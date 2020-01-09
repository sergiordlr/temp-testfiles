Role that creates a peer connection between 2 PVCs

Remember that agnosticd deploys 2 PVCs for 4.x clusters. Usually we want to peer the one with the name "cluster-{{guid}}-randomstring"


How to:

ansible-playbook peer_clusters.yml  -e tgt_name=TARGETTAGNAMEFILTER -e src_name=SOURCERTAGNAMEFILTER -e region=MYREGION


for instance:

ansible-playbook peer_clusters.yml  -e "tgt_name=cluster-myguid-\*" -e "src_name=myotherguid\*" -e region=us-east-1

