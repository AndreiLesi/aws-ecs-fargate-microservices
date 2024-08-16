provider "aws" {
  region = local.region
}

locals {
  name   = "microservices"
  region = "eu-central-1"

  db_container_port = 5432 # Container port is specific to this app example
  db_container_name = "service-db"
  user_container_port = 80 # Container port is specific to this app example
  user_container_name = "service-users"
  products_container_port = 80 # Container port is specific to this app example
  products_container_name = "service-products"
  orders_container_port = 80 # Container port is specific to this app example
  orders_container_name = "service-orders"

  tags = {
    Blueprint  = local.name
    GithubRepo = "github.com/aws-ia/ecs-blueprints"
  }
}

################################################################################
# ECS Blueprint
################################################################################

module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "~> 9.0"

  name = local.name

  # For example only
  enable_deletion_protection = false

  vpc_id  = data.aws_vpc.vpc.id
  subnets = data.aws_subnets.public.ids
  security_group_ingress_rules = {
    all_http = {
      from_port   = 80
      to_port     = 80
      ip_protocol = "tcp"
      description = "HTTP web traffic"
      cidr_ipv4   = "0.0.0.0/0"
    }
  }
  security_group_egress_rules = { for subnet in data.aws_subnet.private_cidr :
    (subnet.availability_zone) => {
      ip_protocol = "-1"
      cidr_ipv4   = subnet.cidr_block
    }
  }


  listeners = {
    http = {
      port     = "80"
      protocol = "HTTP"

      fixed_response = {
        type = "fixed-response"
        content_type = "text/plain"
        message_body = "Hello from the Loadbalancer"
        status_code  = "200"
      }
    

      rules = {
        forward_users = {
          priority = 100
          actions = [{
            type             = "forward"
            target_group_key = local.user_container_name
          }]

          conditions = [{
            path_pattern = {
              values = ["/users*"]
            }
          }]     
        }
        forward_orders = {
          priority = 200
          actions = [{
            type             = "forward"
            target_group_key = local.orders_container_name
          }]

          conditions = [{
            path_pattern = {
              values = ["/orders*"]
            }
          }]     
        }
        forward_products = {
          priority = 300
          actions = [{
            type             = "forward"
            target_group_key = local.products_container_name
          }]

          conditions = [{
            path_pattern = {
              values = ["/products*"]
            }
          }]     
        }
      }
    }
  }


  target_groups = {
    (local.user_container_name) = {
      backend_protocol = "HTTP"
      backend_port     = local.user_container_port
      target_type      = "ip"
      name = local.user_container_name

      health_check = {
        enabled             = true
        healthy_threshold   = 5
        interval            = 30
        matcher             = "200-299"
        path                = "/users"
        port                = "traffic-port"
        protocol            = "HTTP"
        timeout             = 5
        unhealthy_threshold = 2
      }

      # There's nothing to attach here in this definition. Instead,
      # ECS will attach the IPs of the tasks to this target group
      create_attachment = false
    }
    (local.products_container_name) = {
      backend_protocol = "HTTP"
      backend_port     = local.products_container_port
      target_type      = "ip"
      name = local.products_container_name

      health_check = {
        enabled             = true
        healthy_threshold   = 5
        interval            = 30
        matcher             = "200-299"
        path                = "/products"
        port                = "traffic-port"
        protocol            = "HTTP"
        timeout             = 5
        unhealthy_threshold = 2
      }

      # There's nothing to attach here in this definition. Instead,
      # ECS will attach the IPs of the tasks to this target group
      create_attachment = false
    }
    (local.orders_container_name) = {
      backend_protocol = "HTTP"
      backend_port     = local.orders_container_port
      target_type      = "ip"
      name = local.orders_container_name

      health_check = {
        enabled             = true
        healthy_threshold   = 5
        interval            = 30
        matcher             = "200-299"
        path                = "/orders"
        port                = "traffic-port"
        protocol            = "HTTP"
        timeout             = 5
        unhealthy_threshold = 2
      }

      # There's nothing to attach here in this definition. Instead,
      # ECS will attach the IPs of the tasks to this target group
      create_attachment = false
    }
  }

  tags = local.tags
}

################################################################################
# Supporting Resources
################################################################################

data "aws_vpc" "vpc" {
  filter {
    name   = "tag:Name"
    values = ["microservices"]
  }
}

data "aws_subnets" "public" {
  filter {
    name   = "tag:Name"
    values = ["microservices-public-*"]
  }
}

data "aws_subnets" "private" {
  filter {
    name   = "tag:Name"
    values = ["microservices-private-*"]
  }
}

data "aws_subnet" "private_cidr" {
  for_each = toset(data.aws_subnets.private.ids)
  id       = each.value
}

data "aws_ecs_cluster" "core_infra" {
  cluster_name = "microservices"
}

data "aws_service_discovery_dns_namespace" "this" {
  name = "default.${data.aws_ecs_cluster.core_infra.cluster_name}.local"
  type = "DNS_PRIVATE"
}
