# Variables for the lab infrastructure

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
  default     = "lab-complete-rg"
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "West US 2"
}

variable "prefix" {
  description = "Prefix for resource names"
  type        = string
  default     = "lab"
}

variable "admin_username" {
  description = "Administrator username for VMs"
  type        = string
  default     = "labadmin"
}

variable "admin_password" {
  description = "Administrator password for VMs"
  type        = string
  sensitive   = true
}

variable "vm_size" {
  description = "Size of the VMs"
  type        = string
  default     = "Standard_B2s"
}

variable "auto_shutdown_time" {
  description = "Time for auto-shutdown (24-hour format)"
  type        = string
  default     = "18:00"
}
