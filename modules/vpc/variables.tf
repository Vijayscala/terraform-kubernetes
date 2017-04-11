variable "vpc_name" {
  description = "Name of VPC"
}

variable "vpc_cidr" {
  description = "CIDR for the whole VPC"
}

variable "public_subnet_map" {
  description = "Public Subnet Mapping - { Zone = CIDR .... }"
  type        = "map"
}
