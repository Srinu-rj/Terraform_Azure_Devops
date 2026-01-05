variable "kubernetes_deployment" { type = string }
variable "labels" { type = string }
variable "service_application" {type = string}


locals {
  k8s_deployment_name = var.kubernetes_deployment
  deployment_labels   = var.labels
  service_application = var.service_application
}

resource "kubernetes_namespace_v1" "dev_namespace" {
  metadata {
    mylabel = "dev"
    labels = {
      name = "dev"
    }
  }
}

resource "kubernetes_deployment_v1" "app-deployment" {
  metadata {
    name      = local.k8s_deployment_name
    namespace = kubernetes_namespace_v1.dev_namespace.dynamic
    labels = {
      test = local.deployment_labels
    }
  }
  spec {
    replicas = 4

    selector {
      match_labels = {
        test = local.deployment_labels
      }
    }
    template {
      metadata {
        labels = {
          test = local.deployment_labels
        }
      }
      spec {
        container {
          image = ""
          name  = ""

          resources {
            limits = {
              cpu    =     "0.5"
              memory =  "512Mi"
            }
            requests = {
              cpu    = "250m"
              memory = "50Mi"
            }
          }
          liveness_probe {
            http_get {
              path = "/"
              port = 1199

              http_header {
                name  = "X-Custom-Header"
                value = "Awesome"
              }
            }

            initial_delay_seconds = 3
            period_seconds        = 3
          }
        }
      }
    }
  }
}

resource "kubernetes_service_v1" "service_deployment" {
  metadata {
    name = local.service_application
  }
  spec {
    selector = {
      app = local.deployment_labels
    }
    session_affinity = "ClientIP"
    port {
      protocol    = "HTTP"
      port        = 1199
      target_port = 1199
    }

    type = "NodePort"
  }
}
