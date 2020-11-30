output "app_url" {
  value = "http://${data.terraform_remote_state.aws_demo.outputs.f5_vs1[1]}:80"
}

resource "null_resource" "slack" {
  provisioner "local-exec" {
    command = "curl -X POST -H 'Content-type: application/json' --data '{\"text\":\"APP URL : http://${data.terraform_remote_state.aws_demo.outputs.f5_vs1[1]}:80\n\"}' https://hooks.slack.com/services/${var.slack}"
  }
}

variable slack {
  description = "example slack webhook"
  type        = string
  default     = "TQJGFGSVD/BR2D7AN06/2Bsc8hKCUlokflbqPDiKAzLP"
}
