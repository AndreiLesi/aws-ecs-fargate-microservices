module "ecs_service_db" {
  source  = "terraform-aws-modules/ecs/aws//modules/service"
  version = "~> 5.6"

  name          = local.db_container_name
  desired_count = 1
  cluster_arn   = data.aws_ecs_cluster.core_infra.arn
  cpu = 256
  memory = 512

  # Task Definition
  enable_execute_command = true
  enable_autoscaling = false
  container_definitions = {
    (local.db_container_name) = {
      image                    = "975050378797.dkr.ecr.eu-central-1.amazonaws.com/service-db"
      readonly_root_filesystem = false

      port_mappings = [
        {
          protocol      = "tcp",
          containerPort = local.db_container_port
        }
      ]
    }
  }

  service_registries = {
    registry_arn = aws_service_discovery_service.db.arn
  }

  subnet_ids = data.aws_subnets.private.ids
  security_group_rules = {
    ingress_alb_service = {
      type                     = "ingress"
      from_port                = local.db_container_port
      to_port                  = local.db_container_port
      protocol                 = "tcp"
      description              = "Service port"
      # source_security_group_id = 
      cidr_blocks = [data.aws_vpc.vpc.cidr_block]
    }
    egress_all = {
      type        = "egress"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  tags = local.tags
}

resource "aws_service_discovery_service" "db" {
  name = local.db_container_name

  dns_config {
    namespace_id = data.aws_service_discovery_dns_namespace.this.id

    dns_records {
      ttl  = 10
      type = "A"
    }

    routing_policy = "MULTIVALUE"
  }

  health_check_custom_config {
    failure_threshold = 1
  }
}

