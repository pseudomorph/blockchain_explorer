# TODO: Move this to a Helm chart

resource "kubernetes_namespace" "bce" {
  metadata {
    name = "bce"
  }
}


resource "kubernetes_deployment" "deployment-bce" {
  metadata {
    namespace = "bce"
    name      = "deployment-bce"
  }
  spec {
    selector {
      match_labels = {
        "app.kubernetes.io/name" = "app-bce"
      }
    }
    replicas = 5
    template {
      metadata {
        labels = {
          "app.kubernetes.io/name" = "app-bce"
        }
      }
      spec {
        container {
          image = "874046767325.dkr.ecr.us-east-2.amazonaws.com/blockchain_explorer:latest"
          name  = "app-bce"
          port {
            container_port = 8000
          }
        }
      }
    }
  }
  lifecycle {
    ignore_changes = ["spec[0].template[0].spec[0].container[0].image"] # Image will change with codedeploy builds; ignore
  }
}

resource "kubernetes_service" "example" {
  metadata {
    namespace = "bce"
    name      = "service-bce"
  }
  spec {
    port {
      port        = 80
      target_port = 8000
      protocol    = "TCP"
    }
    type = "NodePort"
    selector = {
      "app.kubernetes.io/name" = "app-bce"
    }
  }
}


resource "kubernetes_ingress_v1" "example_ingress" {
  metadata {
    namespace = "bce"
    name      = "ingress-bce"
    annotations = {
      "alb.ingress.kubernetes.io/scheme"               = "internet-facing"
      "alb.ingress.kubernetes.io/target-type"          = "ip"
      "alb.ingress.kubernetes.io/certificate-arn"      = aws_acm_certificate.example.arn
      "alb.ingress.kubernetes.io/listen-ports"         = "[{\"HTTP\": 80}, {\"HTTPS\":443}]"
      "alb.ingress.kubernetes.io/ssl-redirect" = "443"
    }
  }
  spec {
    ingress_class_name = "alb"
    rule {
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = "service-bce"
              port {
                number = 80
              }
            }
          }
        }
      }
    }
  }
}


# TODO: Parameterise inputs and leverage external-dns and cert-manager addons
resource "aws_acm_certificate" "example" {
  domain_name       = "bce.trou7.com"
  validation_method = "DNS"
}

data "aws_route53_zone" "example" {
  name         = "trou7.com"
  private_zone = false
}

resource "aws_route53_record" "example" {
  for_each = {
    for dvo in aws_acm_certificate.example.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.example.zone_id
}

data "kubernetes_ingress_v1" "example" {
  metadata {
    name      = "ingress-bce"
    namespace = "bce"
  }
}

resource "aws_route53_record" "bce" {
  zone_id = data.aws_route53_zone.example.zone_id
  name    = "bce.trou7.com"
  type    = "CNAME"
  ttl     = "300"
  records = [data.kubernetes_ingress_v1.example.status.0.load_balancer.0.ingress.0.hostname]
}