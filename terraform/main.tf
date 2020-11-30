data "http" "myip" {
  url = "https://ifconfig.me"
}


resource "random_string" "password" {
  length  = 10
  special = false
}
