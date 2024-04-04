
alias filterlog="sed 's/\\\\n/\\n\\r/g'"

alias login2build='function __lgb() { unset -f __lgb; ansible-playbook  /usr/local/etc/login2flexybuild.yml -e build_number=$1; }; __lgb'

alias daemonfromnode='function __lgb() { unset -f __lgb; oc get pods -n openshift-machine-config-operator -l "k8s-app=machine-config-daemon" --field-selector "spec.nodeName=$1"; }; __lgb'

#]$  nodelogs ip-10-0-198-67.us-east-2.compute.internal
# or
#]$  nodelogs ip-10-0-198-67.us-east-2.compute.internal -f
alias nodelogs='function __lgb() { unset -f __lgb; oc logs -n openshift-machine-config-operator $(oc get pods -n openshift-machine-config-operator -l "k8s-app=machine-config-daemon" --field-selector "spec.nodeName=$1" -o jsonpath="{.items[0].metadata.name}") -c machine-config-daemon $2; }; __lgb'

alias cvometrics="oc rsh -n openshift-monitoring prometheus-k8s-0 sh -c 'curl -s -k  -H \"Authorization: Bearer \$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)\" https://'\$(oc get svc -n openshift-cluster-version cluster-version-operator -o jsonpath='{.spec.clusterIP}:{.spec.ports[0].port}')'/metrics'"

alias mccmetrics='oc rsh -n openshift-monitoring prometheus-k8s-0 sh -c '\''curl -s -k  -H "Authorization: Bearer $(cat /var/run/secrets/kubernetes.io/serviceaccount/token)" https://'\''$(oc get svc -n openshift-machine-config-operator machine-config-controller -o jsonpath='\''{.spec.clusterIP}:{.spec.ports[0].port}'\'')'\''/metrics'\'''

alias mcdmetrics='oc rsh -n openshift-monitoring prometheus-k8s-0 sh -c '\''curl -s -k  -H "Authorization: Bearer $(cat /var/run/secrets/kubernetes.io/serviceaccount/token)" https://'\''$(oc get svc -n openshift-machine-config-operator machine-config-daemon -o jsonpath='\''{.spec.clusterIP}:{.spec.ports[0].port}'\'')'\''/metrics'\'''

alias alerts='curl -s -k -H "Authorization: Bearer $(oc -n openshift-monitoring create token prometheus-k8s)" https://$(oc get route -n openshift-monitoring alertmanager-main -o jsonpath={.spec.host})/api/v1/alerts | jq '

alias thanosalerts='curl -s -k -H "Authorization: Bearer $(oc -n openshift-monitoring create token prometheus-k8s)" https://$(oc get route -n openshift-monitoring thanos-querier -o jsonpath={.spec.host})/api/v1/alerts | jq '

# ]$ prometheusquery 'mcd_kubelet_state{node="ip-10-0-198-67.us-east-2.compute.internal"}' | jq
alias prometheusquery='function __lgb() { unset -f __lgb; oc rsh -n openshift-monitoring prometheus-k8s-0 curl -s -k  -H "Authorization: Bearer $(oc -n openshift-monitoring create token prometheus-k8s)" --data-urlencode "query=$1" https://prometheus-k8s.openshift-monitoring.svc:9091/api/v1/query; }; __lgb'

alias thanosquery='function __lgb() { unset -f __lgb; oc rsh -n openshift-monitoring prometheus-k8s-0 curl -s -k  -H "Authorization: Bearer $(oc -n openshift-monitoring create token prometheus-k8s)" --data-urlencode "query=$1" https://thanos-querier.openshift-monitoring.svc:9091/api/v1/query | jq -c | jq; }; __lgb'

alias ctrlogs="oc -n openshift-machine-config-operator logs \$(oc -n openshift-machine-config-operator get pods -l k8s-app=machine-config-controller -o jsonpath='{.items[0].metadata.name}') -c machine-config-controller $@"

alias podsinnode='function __lgb() { unset -f __lgb; oc get pods   --all-namespaces -o wide --field-selector spec.nodeName=$1; }; __lgb'

# copy2node ip-10-0-198-67.us-east-2.compute.internal /my/local/file.file /my/host/file.copy
alias copy2node='function __lgb() { unset -f __lgb; oc cp $2 openshift-machine-config-operator/$(oc get pods -n openshift-machine-config-operator -l "k8s-app=machine-config-daemon" --field-selector "spec.nodeName=$1" -ojsonpath="{.items[0].metadata.name}"):/rootfs/$3; }; __lgb'

alias copyfromnode='function __lgb() { unset -f __lgb; oc cp openshift-machine-config-operator/$(oc get pods -n openshift-machine-config-operator -l "k8s-app=machine-config-daemon" --field-selector "spec.nodeName=$1" -ojsonpath="{.items[0].metadata.name}"):/rootfs$2 $3; }; __lgb'

alias ocpupgrade='function __lgb() { unset -f __lgb; oc adm upgrade --to-image=$1  --force --allow-explicit-upgrade; }; __lgb'

alias wdebug='function __lgb() { unset -f __lgb; oc debug -q node/$(oc get nodes -l node-role.kubernetes.io/worker -ojsonpath="{.items[0].metadata.name}") $@; }; __lgb'

alias mdebug='function __lgb() { unset -f __lgb; oc debug -q node/$(oc get nodes -l node-role.kubernetes.io/master -ojsonpath="{.items[0].metadata.name}") $@; }; __lgb'

alias nodeevents='function __lgb() { unset -f __lgb; set -x; oc get events -n default --sort-by lastTimestamp --field-selector "involvedObject.name=$1"; set +x; }; __lgb'
alias nodeeventsbyreason='function __lgb() { unset -f __lgb; set -x; oc get events -n default --sort-by lastTimestamp --field-selector "involvedObject.name=$1,reason=$2"; set +x; }; __lgb'

alias getpullsecret='function __lgb() { unset -f __lgb; set -x; oc get secret pull-secret -n openshift-config --template="{{index .data \".dockerconfigjson\" | base64decode}}" | jq; set +x; }; __lgb'
alias setpullsecret='function __lgb() { unset -f __lgb; set -x; oc set data secret pull-secret -n openshift-config --from-file=.dockerconfigjson=$1; set +x; }; __lgb'

alias nodeswithconfigs='oc get node -o custom-columns="NAME":.metadata.name,"ROLE":"node\-role\.kubernetes\.io/master","ZONE":".metadata.labels.topology\.kubernetes\.io/zone","CURRENT CONFIG":".metadata.annotations.machineconfiguration\.openshift\.io/currentConfig","DESIRED CONFIG":".metadata.annotations.machineconfiguration\.openshift\.io/desiredConfig"'
