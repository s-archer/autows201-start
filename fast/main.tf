data "terraform_remote_state" "aws_demo" {
  backend = "local"

  config = {
    path = "${path.module}/../terraform/terraform.tfstate"
  }
}


resource "null_resource" "fast_app" {
  provisioner "local-exec" {
    command = "curl -k -u ${data.terraform_remote_state.aws_demo.outputs.f5_username}:${data.terraform_remote_state.aws_demo.outputs.f5_password} -X POST -H 'Content-type: application/json' --data-binary \"@${path.module}/rendered_fast.json\" ${data.terraform_remote_state.aws_demo.outputs.f5_ui}/mgmt/shared/fast/applications"
  }
}

# For testing, write out to file

resource "local_file" "rendered_fast_template" {
  content              = templatefile("../templates/fast.tpl", {

    tenant_name      = "terraformFAST"
    application_name = "App01"
    virtual_port     = 80
    virtual_address  = "10.2.1.101"
    server_port      = 80
    server_addresses = ["10.2.1.201", "10.2.1.202"]

  })
  filename = "${path.module}/rendered_fast.json"
}