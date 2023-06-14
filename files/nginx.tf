data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_autoscaling_group" "nginx" {
  name                 = format("%s-nginx-asg", var.prefix)
  launch_configuration = aws_launch_configuration.nginx.name
  desired_capacity     = 2
  min_size             = 1
  max_size             = 4
  vpc_zone_identifier  = [module.vpc.private_subnets[0]]
  depends_on           = [aws_route.internal]

  lifecycle {
    create_before_destroy = true
  }

  tag {
      key                 = "Name"
      value               = format("%s-nginx-asg", var.prefix)
      propagate_at_launch = true
  }
  tag {
      key                 = "Env"
      value               = "consul"
      propagate_at_launch = true
  }
  tag {
      key                 = "UK-SE"
      value               = var.uk_se_name
      propagate_at_launch = true
  }
}

resource "aws_launch_configuration" "nginx" {
  name_prefix                 = format("%s-nginx-", var.prefix)
  image_id                    = data.aws_ami.ubuntu.id
  instance_type               = "t2.micro"
  associate_public_ip_address = false

  security_groups      = [aws_security_group.nginx.id]
  key_name             = aws_key_pair.demo.key_name
  user_data            = file("../scripts/nginx.sh")
  iam_instance_profile = aws_iam_instance_profile.nginx.name


  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_eip" "nginx_nat_gateway" {
  domain = "vpc"
  tags = {
    Name  = format("%s-nginx_nat_gateway_eip", var.prefix)
    UK-SE = "arch"
  }
}

resource "aws_nat_gateway" "nginx" {
  allocation_id = aws_eip.nginx_nat_gateway.id
  subnet_id     = module.vpc.public_subnets[1]

  tags = {
    Name  = format("%s-nginx_nat_gateway", var.prefix)
    UK-SE = "arch"
  }
}

resource "aws_route" "internal" {
  route_table_id         = module.vpc.private_route_table_ids[0]
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nginx.id
}

resource "aws_iam_role_policy" "nginx" {
  name = "${var.prefix}nginx"
  role = aws_iam_role.nginx.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "ec2:DescribeInstances",
        "ec2:DescribeTags",
        "autoscaling:DescribeAutoScalingGroups"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_role" "nginx" {
  name = "${var.prefix}nginx"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_instance_profile" "nginx" {
  name = "${var.prefix}nginx"
  role = aws_iam_role.nginx.name
}