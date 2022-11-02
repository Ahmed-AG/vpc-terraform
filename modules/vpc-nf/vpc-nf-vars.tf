#global variables

variable "environment_tag" {
  description = "vpc environment tag"
  type = string
}

variable "key_name" {
  description = "instances key name"
  type = string
  default = "N-Vkey"
}

#vpc variables
variable "vpc_cidr_block" {
  description = "CIDR Block"
  type = string
  default = "10.10.0.0/16"
}

#subnets variables
variable "fw_cidr_block" {
  description = "CIDR Block"
  type = string 
  default = "10.10.0.0/24"
}

variable "internal_cidr_block" {
  description = "CIDR Block"
  type = string 
  default = "10.10.1.0/24"
}

#instances variables
variable "web01_ami" {
  description = "ami ID"
  type = string 
  default = "ami-04bf6dcdc9ab498ca"
}


variable "instance_type" {
  description = "Instance type"
  type = string 
  default = "t2.micro"
}
