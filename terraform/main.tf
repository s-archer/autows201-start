data "http" "myip" {
  url = "https://ifconfig.me"
}


resource "random_string" "password" {
  length  = 10
  special = false
}

data "aws_ami" "bigip" {
  most_recent = true
  owners      = ["679593333241"]

  filter {
    name   = "name"
    values = ["*BIGIP-15.1.0.4*Good*25Mbps*"]
  }
}

output "bigip_ami" {
  value = data.aws_ami.bigip.id
}

