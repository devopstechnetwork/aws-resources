# ---------------------------------------------------------------------------------------------------------------------
# DEPLOY APPLICATION LOADBALANCER
# Author : SANJIB BEHERA
# Version: SB_0.1
# ---------------------------------------------------------------------------------------------------------------------

## Create Security Group for ELB
resource "aws_security_group" "sanjib_elb_sg" {
  name               = "sanjib-elb-sg"
  vpc_id             = var.vpc_id
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create Application Load balancer..
resource "aws_lb" "sanjib_elb" {
  name               = "sanjib-elb-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = ["${aws_security_group.sanjib_elb_sg.id}"]
  subnets            = var.subnets

  tags = {
    Environment = "dev-elb"
  } 

  depends_on = [
      aws_security_group.sanjib_elb_sg
  ]
}

# Create Load balancer Listener.
resource "aws_lb_listener" "sanjib_elb_listener" {
  load_balancer_arn = aws_lb.sanjib_elb.arn
  port              = var.elb_lb_port
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.sanjib_elb_target_grp.arn
  } 

  depends_on = [
      aws_lb_target_group.sanjib_elb_target_grp
  ]
}

# Create Load balancer Target Group which will point to the Apache webserver EC2 Instances.
resource "aws_lb_target_group" "sanjib_elb_target_grp" {
  name     = "sanjib-elb-alb-tg"
  port     = var.elb_instance_http_port
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    port                = var.health_port
    protocol            = var.protocol
    healthy_threshold   = var.healthy_threshold
    unhealthy_threshold = var.unhealthy_threshold
    interval            = var.health_check_interval
  }
}

# Create the Target Group attachment which will attach the target group to the backend i.e. the EC2 instances.
resource "aws_lb_target_group_attachment" "sanjib_elb_grp_attach" {
    target_group_arn = aws_lb_target_group.sanjib_elb_target_grp.arn
    count            = var.attachment_count
    target_id        = var.target_id[count.index]
    port             = var.elb_instance_http_port
}

# Create the Security Group rule which will modily the security group ingress rule such that Load balancer
# can only reach the backend i.e. the Apache webserver EC2 instances on port 80
resource "aws_security_group_rule" "public_sg" {
  type                        = "ingress"
  from_port                   = 80
  to_port                     = 80
  protocol                    = "tcp"
  source_security_group_id    = aws_security_group.sanjib_elb_sg.id
  security_group_id           = var.security_group_id

  depends_on = [
      aws_security_group.sanjib_elb_sg
  ]
}

# Create the Security Group rule which will modily the security group egress rule such that 
# Apache webserver EC2 instances can respond to the Load balancer on every port and every protocol.
resource "aws_security_group_rule" "allow_all" {
  type                        = "egress"
  from_port                   = 0
  to_port                     = 0
  protocol                    = "-1"
  source_security_group_id    = aws_security_group.sanjib_elb_sg.id
  security_group_id           = var.security_group_id
}