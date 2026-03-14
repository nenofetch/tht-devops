variable "subcription" {
  description = "Azure Subcription"
  type = string
}

variable "region" {
  description = "Azure region"
  type        = string
  default     = "Central India"
}
variable "instance_name" {
  description = "Name of the virtual machine"
  type        = string
  default     = "otf-web"
}
variable "ssh_public_key_path" {
  description = "Path to SSH public key"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

variable "vcn_cidr" {
  description = "Virtual Network CIDR"
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_cidr" {
  description = "Subnet CIDR"
  type        = string
  default     = "10.0.1.0/24"
}
