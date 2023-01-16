locals {
  node_cpu_request = "${(var.elasticsearch_node_cpu / 2) * 1000}m"
  node_cpu_limit = "${var.elasticsearch_node_cpu * 1000}m"
  node_ram_request = "${var.elasticsearch_node_ram}Gi"
  node_ram_limit = "${var.elasticsearch_node_ram}Gi"
  node_storage_size = "${var.elasticsearch_node_storage_size}Gi"
  # render helm chart values since direct passing of values does not work in all cases
  rendered_values = <<EOT
clusterName: "${var.elasticsearch_cluster_name}"
roles:
  master: "true"
  ingest: "false"
  data: "true"
  remote_cluster_client: "false"
  ml: "false"
  transform: "false"
replicas: ${var.elasticsearch_cluster_size}
minimumMasterNodes: 2
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
%{ if var.elasticsearch_backup_restore_enabled ~}
  - name: AZURE_SNAPSHOT_CONTAINER
    value: "elasticsearch-snapshots"
  - name: AZURE_SNAPSHOT_BASE_PATH
    value: "/cancom-backup/"
  - name: SNAPSHOT_NAME
    value: "snapshot_test_token"
  - name: TOKEN_INDEX_NAME
    value: "test_token"
  - name: REQUESTLOG_INDEX_NAME
    value: "test_requestlog"
%{ endif ~}
esConfig:
  elasticsearch.yml: |
    xpack.security.enabled: ${var.elasticsearch_security_enabled}
resources:
  requests:
    cpu: "${local.node_cpu_request}"
    memory: "${local.node_ram_request}"
  limits:
    cpu: "${local.node_cpu_limit}"
    memory: "${local.node_ram_limit}"
volumeClaimTemplate:
  storageClassName: "${var.elasticsearch_node_storage_class}"
  accessModes: [ "ReadWriteOnce" ]
  resources:
    requests:
      storage: "${local.node_storage_size}"
rbac:
  create: true
persistence:
  enabled: true
  labels:
    enabled: false
antiAffinity: ${var.topology_spread_strategy}
%{ if var.node_group_workload_class != "" ~}
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
podManagementPolicy: "Parallel"
enableServiceLinks: true
protocol: http
httpPort: 9200
transportPort: 9300
service:
  type: ClusterIP
updateStrategy: RollingUpdate
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
terminationGracePeriod: 120
sysctlVmMaxMapCount: 262144
readinessProbe:
  failureThreshold: 3
  initialDelaySeconds: 10
  periodSeconds: 10
  successThreshold: 3
  timeoutSeconds: 5
clusterHealthCheckParams: "wait_for_status=green&timeout=1s"
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
%{ if var.elasticsearch_backup_restore_enabled ~}
image: ${var.elasticsearch_image_name}
imageTag: ${var.elasticsearch_image_tag}
imagePullPolicy: "Always"
keystore:
  - secretName: ${kubernetes_secret.elasticsearch_restore[0].metadata[0].name}
%{ endif ~}
%{ if var.node_group_workload_class != "" ~}
# It's OK to be deployed to the tools pool, too
tolerations:
  - key: "group.msg.cloud.kubernetes/workload"
    operator: "Equal"
    value: ${var.node_group_workload_class}
    effect: "NoSchedule"
%{ endif ~}
EOT
}

resource helm_release elasticsearch {
  chart = "elasticsearch"
  version = "7.15.0"
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