locals {
  node_cpu_request = "${(var.elasticsearch_node_cpu / 2) * 1000}m"
  node_cpu_limit = "${var.elasticsearch_node_cpu * 1000}m"
  node_ram_request = "${var.elasticsearch_node_ram}Gi"
  node_ram_limit = "${var.elasticsearch_node_ram}Gi"
  node_storage_size = "${var.elasticsearch_node_storage_size}Gi"
  # render helm chart values since direct passing of values does not work in all cases
  rendered_values = <<EOT
clusterName: "${var.elasticsearch_cluster_name}"
nodeGroup: "master"

# The service that non master groups will try to connect to when joining the cluster
# This should be set to clusterName + "-" + nodeGroup for your master group
masterService: ""

# Elasticsearch roles that will be applied to this nodeGroup
# These will be set as environment variables. E.g. node.roles=master
# https://www.elastic.co/guide/en/elasticsearch/reference/current/modules-node.html#node-roles
roles:
  - master
  - data
replicas: ${var.elasticsearch_cluster_size}
minimumMasterNodes: 2

esMajorVersion: ""

# Allows you to add any config files in /usr/share/elasticsearch/config/
# such as elasticsearch.yml and log4j2.properties
esConfig:
  elasticsearch.yml: |
    xpack.security.enabled: ${var.elasticsearch_security_enabled}

createCert: true

esJvmOptions: {}
#  processors.options: |
#    -XX:ActiveProcessorCount=3

# Extra environment variables to append to this nodeGroup
# This will be appended to the current 'env:' key. You can use any of the kubernetes env
# syntax here
extraEnvs:
  - name: bootstrap.memory_lock
    value: "false"
%{ if var.elasticsearch_security_enabled ~}
  # provide Elasticsearch username and password via Kubernetes secret
  - name: ELASTIC_PASSWORD
    valueFrom:
      secretKeyRef:
        name: ${kubernetes_secret.elasticsearch.0.metadata.0.name}
        key: elasticsearch-password
  - name: ELASTIC_USERNAME
    valueFrom:
      secretKeyRef:
        name: ${kubernetes_secret.elasticsearch.0.metadata.0.name}
        key: elasticsearch-user
%{ endif ~}

# Allows you to load environment variables from kubernetes secret or config map
envFrom: []
# - secretRef:
#     name: env-secret
# - configMapRef:
#     name: config-map

# Disable it to use your own elastic-credential Secret.
secret:
  enabled: true
  password: "" # generated randomly if not defined

# A list of secrets and their paths to mount inside the pod
# This is useful for mounting certificates for security and for mounting
# the X-Pack license
secretMounts: []
#  - name: elastic-certificates
#    secretName: elastic-certificates
#    path: /usr/share/elasticsearch/config/certs
#    defaultMode: 0755

hostAliases: []
#- ip: "127.0.0.1"
#  hostnames:
#  - "foo.local"
#  - "bar.local"

image: "docker.elastic.co/elasticsearch/elasticsearch"
imageTag: "8.5.1"
imagePullPolicy: "IfNotPresent"

podAnnotations: {}
# iam.amazonaws.com/role: es-cluster

# additionals labels
labels: {}

esJavaOpts: "" # example: "-Xmx1g -Xms1g"

resources:
  requests:
    cpu: "${local.node_cpu_request}"
    memory: "${local.node_ram_request}"
  limits:
    cpu: "${local.node_cpu_limit}"
    memory: "${local.node_ram_limit}"

initResources: {}
# limits:
#   cpu: "25m"
#   # memory: "128Mi"
# requests:
#   cpu: "25m"
#   memory: "128Mi"

networkHost: "0.0.0.0"

volumeClaimTemplate:
  storageClassName: "${var.elasticsearch_node_storage_class}"
  accessModes: ["ReadWriteOnce"]
  resources:
    requests:
      storage: "${local.node_storage_size}"

rbac:
  create: true
  serviceAccountAnnotations: {}
  serviceAccountName: ""
  automountToken: true

podSecurityPolicy:
  create: false
  name: ""
  spec:
    privileged: true
    fsGroup:
      rule: RunAsAny
    runAsUser:
      rule: RunAsAny
    seLinux:
      rule: RunAsAny
    supplementalGroups:
      rule: RunAsAny
    volumes:
      - secret
      - configMap
      - persistentVolumeClaim
      - emptyDir

persistence:
  enabled: true
  labels:
    # Add default labels for the volumeClaimTemplate of the StatefulSet
    enabled: false
  annotations: {}

extraVolumes: []
# - name: extras
#   emptyDir: {}

extraVolumeMounts: []
# - name: extras
#   mountPath: /usr/share/extras
#   readOnly: true

extraContainers: []
# - name: do-something
#   image: busybox
#   command: ['do', 'something']

extraInitContainers: []
# - name: do-something
#   image: busybox
#   command: ['do', 'something']

# This is the PriorityClass settings as defined in
# https://kubernetes.io/docs/concepts/configuration/pod-priority-preemption/#priorityclass
priorityClassName: ""

# By default this will make sure two pods don't end up on the same node
# Changing this to a region would allow you to spread pods across regions
antiAffinityTopologyKey: "kubernetes.io/hostname"

# Hard means that by default pods will only be scheduled if there are enough nodes for them
# and that they will never end up on the same node. Setting this to soft will do this "best effort"
antiAffinity: ${var.topology_spread_strategy}

# This is the node affinity settings as defined in
# https://kubernetes.io/docs/concepts/configuration/assign-pod-node/#node-affinity-beta-feature
%{ if var.node_group_workload_class != "" ~}
affinity:
  # Encourages deployment to the tools pool
  nodeAffinity:
    requiredDuringSchedulingIgnoredDuringExecution:
      nodeSelectorTerms:
        - matchExpressions:
            - key: "group.msg.cloud.kubernetes/workload"
              operator: In
              values:
                - ${var.node_group_workload_class}
%{ endif ~}

# The default is to deploy all pods serially. By setting this to parallel all pods are started at
# the same time when bootstrapping the cluster
podManagementPolicy: "Parallel"

# The environment variables injected by service links are not used, but can lead to slow Elasticsearch boot times when
# there are many services in the current namespace.
# If you experience slow pod startups you probably want to set this to `false`.
enableServiceLinks: true

protocol: http
httpPort: 9200
transportPort: 9300

service:
  enabled: true
  labels: {}
  labelsHeadless: {}
  type: ClusterIP
  # Consider that all endpoints are considered "ready" even if the Pods themselves are not
  # https://kubernetes.io/docs/reference/kubernetes-api/service-resources/service-v1/#ServiceSpec
  publishNotReadyAddresses: false
  nodePort: ""
  annotations: {}
  httpPortName: http
  transportPortName: transport
  loadBalancerIP: ""
  loadBalancerSourceRanges: []
  externalTrafficPolicy: ""

updateStrategy: RollingUpdate

# This is the max unavailable setting for the pod disruption budget
# The default value of 1 will make sure that kubernetes won't allow more than 1
# of your pods to be unavailable during maintenance
maxUnavailable: 1

podSecurityContext:
  fsGroup: 1000
  runAsUser: 1000

securityContext:
  capabilities:
    drop:
      - ALL
  # readOnlyRootFilesystem: true
  runAsNonRoot: true
  runAsUser: 1000

# How long to wait for elasticsearch to stop gracefully
terminationGracePeriod: 120

sysctlVmMaxMapCount: 262144

readinessProbe:
  failureThreshold: 3
  initialDelaySeconds: 10
  periodSeconds: 10
  successThreshold: 3
  timeoutSeconds: 5

# https://www.elastic.co/guide/en/elasticsearch/reference/current/cluster-health.html#request-params wait_for_status
clusterHealthCheckParams: "wait_for_status=green&timeout=1s"

## Use an alternate scheduler.
## ref: https://kubernetes.io/docs/tasks/administer-cluster/configure-multiple-schedulers/
##
schedulerName: ""

imagePullSecrets: []
nodeSelector: {}
%{ if var.node_group_workload_class != "" ~}
# It's OK to be deployed to the tools pool, too
tolerations:
  - key: "group.msg.cloud.kubernetes/workload"
    operator: "Equal"
    value: ${var.node_group_workload_class}
    effect: "NoSchedule"
%{ endif ~}

# Enabling this will publicly expose your Elasticsearch instance.
# Only enable this if you have security enabled on your cluster
ingress:
  enabled: ${var.public_access_enabled}
%{ if var.public_access_enabled ~}
  annotations:
    kubernetes.io/ingress.class: nginx
  hosts:
    - host: "${var.public_access_host}"
      paths:
        - path: "/elasticsearch/${var.kubernetes_namespace_name}/${var.elasticsearch_cluster_name}"
%{ endif ~}

nameOverride: ""
fullnameOverride: ""
healthNameOverride: ""

lifecycle: {}
# preStop:
#   exec:
#     command: ["/bin/sh", "-c", "echo Hello from the postStart handler > /usr/share/message"]
# postStart:
#   exec:
#     command:
#       - bash
#       - -c
#       - |
#         #!/bin/bash
#         # Add a template to adjust number of shards/replicas
#         TEMPLATE_NAME=my_template
#         INDEX_PATTERN="logstash-*"
#         SHARD_COUNT=8
#         REPLICA_COUNT=1
#         ES_URL=http://localhost:9200
#         while [[ "$(curl -s -o /dev/null -w '%{http_code}\n' $ES_URL)" != "200" ]]; do sleep 1; done
#         curl -XPUT "$ES_URL/_template/$TEMPLATE_NAME" -H 'Content-Type: application/json' -d'{"index_patterns":['\""$INDEX_PATTERN"\"'],"settings":{"number_of_shards":'$SHARD_COUNT',"number_of_replicas":'$REPLICA_COUNT'}}'

sysctlInitContainer:
  enabled: true

keystore: []

networkPolicy:
  ## Enable creation of NetworkPolicy resources. Only Ingress traffic is filtered for now.
  ## In order for a Pod to access Elasticsearch, it needs to have the following label:
  ## {{ template "uname" . }}-client: "true"
  ## Example for default configuration to access HTTP port:
  ## elasticsearch-master-http-client: "true"
  ## Example for default configuration to access transport port:
  ## elasticsearch-master-transport-client: "true"

  http:
    enabled: false
    ## if explicitNamespacesSelector is not set or set to {}, only client Pods being in the networkPolicy's namespace
    ## and matching all criteria can reach the DB.
    ## But sometimes, we want the Pods to be accessible to clients from other namespaces, in this case, we can use this
    ## parameter to select these namespaces
    ##
    # explicitNamespacesSelector:
    #   # Accept from namespaces with all those different rules (only from whitelisted Pods)
    #   matchLabels:
    #     role: frontend
    #   matchExpressions:
    #     - {key: role, operator: In, values: [frontend]}

    ## Additional NetworkPolicy Ingress "from" rules to set. Note that all rules are OR-ed.
    ##
    # additionalRules:
    #   - podSelector:
    #       matchLabels:
    #         role: frontend
    #   - podSelector:
    #       matchExpressions:
    #         - key: role
    #           operator: In
    #           values:
    #             - frontend

  transport:
    ## Note that all Elasticsearch Pods can talk to themselves using transport port even if enabled.
    enabled: false
    # explicitNamespacesSelector:
    #   matchLabels:
    #     role: frontend
    #   matchExpressions:
    #     - {key: role, operator: In, values: [frontend]}
    # additionalRules:
    #   - podSelector:
    #       matchLabels:
    #         role: frontend
    #   - podSelector:
    #       matchExpressions:
    #         - key: role
    #           operator: In
    #           values:
    #             - frontend

tests:
  enabled: true
EOT
}

resource helm_release elasticsearch {
  chart = "elasticsearch"
  version = "8.5.1"
  repository = "https://helm.elastic.co"
  name = var.helm_release_name
  dependency_update = true
  atomic = true
  cleanup_on_fail = true
  namespace = var.kubernetes_namespace_name
  create_namespace = true
  values = [ local.rendered_values ]
  depends_on = [ kubernetes_secret.elasticsearch, kubernetes_secret.elasticsearch_restore[0] ]
}