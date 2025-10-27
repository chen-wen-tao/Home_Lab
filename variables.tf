variable "location" {
  type    = string
  default = "eastus"
}

variable "rg_name" {
  type    = string
  default = "lab-vpn-rg"
}

variable "prefix" {
  type    = string
  default = "10.10"
}

variable "admin_username" {
  type    = string
  default = "labadmin"
}

# Set your public IP/CIDR, e.g., "99.47.21.31/32"
variable "allowed_ip" {
  type    = string
  default = "99.47.21.31/32"
}

variable "admin_password" {
  type = string
}
