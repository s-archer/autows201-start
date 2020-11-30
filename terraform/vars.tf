variable "f5_ami_search_name" {
  description = "filter used to find AMI for deployment"
  default     = "F5*BIGIP-15.1.1*Best*25Mbps*"
}

variable "prefix" {
  description = "prefix used for naming objects created in AWS"
  default     = "arch-autows201-tf-"
}

variable "uk_se_name" {
  description = "UK SE name tag"
  default     = "arch"
}