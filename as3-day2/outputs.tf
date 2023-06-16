output "nginx-web-server" {
  value = "Login to NGINX Web Server here: ${data.terraform_remote_state.aws_demo.outputs.f5_vs1_uri}"
}