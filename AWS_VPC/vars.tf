variable "region" {
  description = "Region Name"
  default = "us-east-1"
}


variable "vpc_cidr" {
  description = "CIDR for the VPC"
  default = "90.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDR for the public subnets"
  type = list(string)
  default = ["90.0.1.0/24","90.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR for the private subnets"
  type = list(string)
  default = ["90.0.3.0/24","90.0.4.0/24"]
}

variable "availability_zones" {
  description = "AZs in this region to use"
  default = ["us-east-1a", "us-east-1b"]
  type = list(string)
}
