resource "aws_network_interface" "mgmt" {
  subnet_id       = module.vpc.public_subnets[0]
  private_ips     = ["10.0.1.10"]
  security_groups = [aws_security_group.mgmt.id]
}

resource "aws_network_interface" "public" {
  subnet_id       = module.vpc.public_subnets[1]
  private_ips     = ["10.0.2.10", "10.0.2.101"]
  security_groups = [aws_security_group.public.id]
}

resource "aws_network_interface" "private" {
  subnet_id   = module.vpc.private_subnets[0]
  private_ips = ["10.0.3.10"]
  security_groups = [aws_security_group.public.id]
}
 
resource "aws_eip" "mgmt" {
  domain                    = "vpc"
  network_interface         = aws_network_interface.mgmt.id
  associate_with_private_ip = "10.0.1.10"
}

resource "aws_eip" "public-self" {
  domain                    = "vpc"
  network_interface         = aws_network_interface.public.id
  associate_with_private_ip = "10.0.2.10"
}

resource "aws_eip" "public-vs1" {
  domain                    = "vpc"
  network_interface         = aws_network_interface.public.id
  associate_with_private_ip = "10.0.2.101"
}

data "aws_ami" "f5_ami" {
  most_recent = true
  # This is the F5 Networks 'owner ID', which ensures we get an image maintained by F5.
  owners = ["679593333241"]

  filter {
    name   = "name"
    values = [var.f5_ami_search_name]
  }
}

resource "random_string" "password" {
  length  = 10
  special = false
}


resource "aws_instance" "f5" {

  ami           = data.aws_ami.f5_ami.id
  instance_type = "t2.medium"
  key_name      = aws_key_pair.demo.key_name
  user_data     = templatefile("../templates/user_data_json.tpl", {
    hostname        = "mybigip.f5.com",
    region          = var.region,
    admin_pass      = random_string.password.result,
    external_ip     = "${aws_eip.public-self.private_ip}/24",
    internal_ip     = "${aws_network_interface.private.private_ip}/24",
    internal_gw     = cidrhost(module.vpc.private_subnets_cidr_blocks[0], 1)
    vs1_ip          = aws_eip.public-vs1.private_ip,
    package_url     = "https://cdn.f5.com/product/cloudsolutions/f5-bigip-runtime-init/v1.6.1/dist/f5-bigip-runtime-init-1.6.1-1.gz.run",
    access_key_id     = var.access_key_id,
    secret_access_key = var.secret_access_key,
    asg_tag           = format("%s-nginx-asg", var.prefix)
  })

  network_interface {
    network_interface_id = aws_network_interface.mgmt.id
    device_index         = 0
  }

  network_interface {
    network_interface_id = aws_network_interface.public.id
    device_index         = 1
  }

  network_interface {
    network_interface_id = aws_network_interface.private.id
    device_index         = 2
  }

  # provisioner "local-exec" {
  #   command = "while [[ \"$(curl -ski http://${aws_eip.public-vs1.public_ip} | grep -Eoh \"^HTTP/1.1 200\")\" != \"HTTP/1.1 200\" ]]; do sleep 5; done"
  # }

  tags = {
    Name     = "${var.prefix}-f5"
    Env      = "aws"
    workshop = "201"
    UK-SE    = var.uk_se_name
  }
}


# data "template_file" "f5_init" {
#   template = file("../templates/user_data_json.tpl")

#   vars = {
#     hostname        = "mybigip.f5.com",
#     admin_pass      = random_string.password.result,
#     external_ip     = "${aws_eip.public-self.private_ip}/24",
#     internal_ip     = "${aws_network_interface.private.private_ip}/24",
#     internal_gw     = cidrhost(module.vpc.private_subnets_cidr_blocks[0], 1)
#     vs1_ip          = aws_eip.public-vs1.private_ip,
#   }
# }

# resource "local_file" "test_user_debug" {
#   content = templatefile("../templates/user_data_json.tpl", {
#     hostname        = "mybigip.f5.com",
#     admin_pass      = random_string.password.result,
#     external_ip     = "${aws_eip.public-self.private_ip}/24",
#     internal_ip     = "${aws_network_interface.private.private_ip}/24",
#     internal_gw     = cidrhost(module.vpc.private_subnets_cidr_blocks[0], 1)
#     vs1_ip          = aws_eip.public-vs1.private_ip,
#   })
#   filename = "${path.module}/user_data_debug.json"
# }