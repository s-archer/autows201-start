data "terraform_remote_state" "aws_demo" {
  backend = "local"

  config = {
    path = "${path.module}/../files/terraform.tfstate"
  }
}

terraform {
  required_providers {
    bigip = {
      source  = "F5Networks/bigip"
      version = "1.10.0"
    }
  }
}

provider "bigip" {
  address  = data.terraform_remote_state.aws_demo.outputs.f5_mgmt_ip
  username = data.terraform_remote_state.aws_demo.outputs.f5_username
  password = data.terraform_remote_state.aws_demo.outputs.f5_password
}

resource "bigip_as3" "as3-day2_tenant" {
  as3_json = templatefile("${path.module}/as3.tpl", {
    app_list          = var.app_list
    asg_tag           = data.terraform_remote_state.aws_demo.outputs.asg_tag
    waf_enable        = false
    access_key_id     = var.access_key_id
    secret_access_key = var.secret_access_key

  })
  tenant_filter = "day2_tenant"
}

# For testing, write out to file

resource "local_file" "rendered_as3" {
  content = templatefile("${path.module}/as3.tpl", {
    #vip = local.pub_vs_eips_list[0].private_ip
    app_list          = var.app_list
    asg_tag           = data.terraform_remote_state.aws_demo.outputs.asg_tag
    waf_enable        = false
    access_key_id     = var.access_key_id
    secret_access_key = "removed"
  })
  filename = "${path.module}/rendered_as3.json"
}