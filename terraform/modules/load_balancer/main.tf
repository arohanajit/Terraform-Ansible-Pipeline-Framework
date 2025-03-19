variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for the load balancer"
  type        = list(string)
}

variable "security_group" {
  description = "Security group ID for load balancer"
  type        = string
}

variable "target_groups" {
  description = "Map of target group configurations"
  type = map(object({
    port     = number
    protocol = string
    targets  = list(string)
  }))
}

resource "aws_lb" "main" {
  name               = "${var.environment}-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.security_group]
  subnets           = var.subnet_ids

  tags = {
    Name        = "${var.environment}-load-balancer"
    Environment = var.environment
  }
}

resource "aws_lb_target_group" "main" {
  for_each = var.target_groups

  name     = "${var.environment}-tg-${each.key}"
  port     = each.value.port
  protocol = each.value.protocol
  vpc_id   = var.vpc_id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval           = 30
    matcher            = "200"
    path               = "/"
    port               = "traffic-port"
    protocol           = each.value.protocol
    timeout            = 5
    unhealthy_threshold = 2
  }
}

resource "aws_lb_target_group_attachment" "main" {
  for_each = {
    for pair in flatten([
      for tg_key, tg in var.target_groups : [
        for idx, target in tg.targets : {
          tg_key   = tg_key
          tg       = tg
          idx      = idx
          target   = target
          key      = "${tg_key}-${idx}"
        }
      ]
    ]) : pair.key => pair
  }
  
  target_group_arn = aws_lb_target_group.main[each.value.tg_key].arn
  target_id        = each.value.target
  port             = each.value.tg.port
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main["web"].arn
  }
}

output "dns_name" {
  description = "DNS name of the load balancer"
  value       = aws_lb.main.dns_name
}

output "zone_id" {
  description = "Zone ID of the load balancer"
  value       = aws_lb.main.zone_id
} 