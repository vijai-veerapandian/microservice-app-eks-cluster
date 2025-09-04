# =====================================================================
# CloudWatch Log Groups for Application Logs
# =====================================================================

# Log group for application logs
resource "aws_cloudwatch_log_group" "application_logs" {
  count             = var.enable_fluentbit ? 1 : 0
  name              = "/aws/eks/${local.name}/application"
  retention_in_days = var.log_retention_days
  tags              = local.tags
}

# Log group for system logs (kube-system namespace)
resource "aws_cloudwatch_log_group" "system_logs" {
  count             = var.enable_fluentbit ? 1 : 0
  name              = "/aws/eks/${local.name}/system"
  retention_in_days = var.log_retention_days
  tags              = local.tags
}

# Log group for dataplane logs (worker nodes)
resource "aws_cloudwatch_log_group" "dataplane_logs" {
  count             = var.enable_fluentbit ? 1 : 0
  name              = "/aws/eks/${local.name}/dataplane"
  retention_in_days = 14 # Shorter retention for node logs
  tags              = local.tags
}

# =====================================================================
# Deploy Fluent Bit via Helm for Log Collection
# =====================================================================

resource "helm_release" "fluent_bit" {
  count = var.enable_fluentbit ? 1 : 0

  name       = "fluent-bit"
  repository = "https://fluent.github.io/helm-charts"
  chart      = "fluent-bit"
  namespace  = "amazon-cloudwatch"
  version    = "0.46.7"

  create_namespace = true

  values = [
    yamlencode({
      serviceAccount = {
        create = true
        name   = "fluent-bit"
        annotations = {
          "eks.amazonaws.com/role-arn" = aws_iam_role.fluent_bit[0].arn
        }
      }

      config = {
        service = {
          parsersFile = "parsers.conf"
          httpServer  = "On"
          httpListen  = "0.0.0.0"
          httpPort    = "2020"
          healthCheck = "On"
        }

        inputs = {
          tail = {
            memBufLimit      = "50MB"
            skipLongLines    = "On"
            refreshInterval  = "10"
            rotatewait       = "30"
            storageType      = "filesystem"
            storageMaxChunks = "3"
          }
        }

        filters = {
          kubernetes = {
            match                   = "kube.*"
            kubeURL                 = "https://kubernetes.default.svc:443"
            kubeCAFile              = "/var/run/secrets/kubernetes.io/serviceaccount/ca.crt"
            kubeTokenFile           = "/var/run/secrets/kubernetes.io/serviceaccount/token"
            kubeMetaPreloadCacheDir = "/fluent-bit/cache"
            mergeLog                = "On"
            keepLog                 = "Off"
            k8sLoggingParser        = "On"
            k8sLoggingExclude       = "On"
            labels                  = "On"
            annotations             = "On"
          }
        }

        outputs = {
          cloudwatch = {
            match             = "*"
            region            = var.aws_region
            logGroupTemplate  = "/aws/eks/${local.name}/$kubernetes['namespace_name']"
            logStreamTemplate = "$kubernetes['pod_name'].$kubernetes['container_name']"
            autoCreateGroup   = "true"
            logRetentionDays  = var.log_retention_days
            logFormat         = "json"
          }
        }
      }

      # Resource limits for Fluent Bit pods
      resources = {
        limits = {
          memory = "200Mi"
          cpu    = "100m"
        }
        requests = {
          memory = "100Mi"
          cpu    = "50m"
        }
      }

      # Tolerations to run on all nodes
      tolerations = [
        {
          key      = "node-role.kubernetes.io/master"
          operator = "Exists"
          effect   = "NoSchedule"
        },
        {
          key      = "node-role.kubernetes.io/control-plane"
          operator = "Exists"
          effect   = "NoSchedule"
        }
      ]

      # Node selector (empty means run on all nodes)
      nodeSelector = {}

      # Update strategy
      updateStrategy = {
        type = "RollingUpdate"
        rollingUpdate = {
          maxUnavailable = 1
        }
      }

      # Additional environment variables
      env = [
        {
          name  = "FLUENT_CONF"
          value = "fluent-bit.conf"
        }
      ]

      # Volume mounts for log collection
      volumeMounts = [
        {
          name      = "varlog"
          mountPath = "/var/log"
          readOnly  = true
        },
        {
          name      = "varlibdockercontainers"
          mountPath = "/var/lib/docker/containers"
          readOnly  = true
        }
      ]

      volumes = [
        {
          name = "varlog"
          hostPath = {
            path = "/var/log"
          }
        },
        {
          name = "varlibdockercontainers"
          hostPath = {
            path = "/var/lib/docker/containers"
          }
        }
      ]
    })
  ]

  depends_on = [
    module.eks,
    aws_cloudwatch_log_group.application_logs,
    aws_cloudwatch_log_group.system_logs,
    aws_cloudwatch_log_group.dataplane_logs
  ]
}
