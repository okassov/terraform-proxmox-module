terraform {
  experiments = [module_variable_optional_attrs]
}

variable "proxmox_api_url" {
  type        = string
  description = "Proxmox API URL for connect"
}

variable "proxmox_api_user" {
  type        = string
  description = "Proxmox username for connect"
}

variable "proxmox_api_pass" {
  type        = string
  description = "Proxmox password for connect"
}

variable "proxmox_ssh_host" {
  type        = string
  description = "Proxmox host IP address or DNS name"
}

variable "proxmox_ssh_port" {
  type        = string
  default     = "22"
  description = "Proxmox host SSH port"
}

variable "proxmox_ssh_user" {
  type        = string
  default     = "root"
  description = "Proxmox host username for SSH connection"
}

variable "proxmox_ssh_private_key" {
  type        = string
  description = "Path to private key for SSH connection"
}

variable "proxmox_unverified_ssl" {
  default     = false
  description = "Verify SSL certificate or not"
}

variable "env" {
  type        = string
  description = "Environment variable for tagging"

  validation {
    condition     = contains(["dev", "stage", "prod", "share"], var.env)
    error_message = "Valid values for env ('dev', 'stage', 'prod', 'share')?"
  }
}

variable "project" {
  type        = string
  description = "Project name"
}

variable "role" {
  type = string
  validation {
    condition     = contains(["db", "compute", "storage", "infra"], var.role)
    error_message = "Valid values for role ('db', 'compute', 'storage', 'infra')?"
  }
}

variable "app" {
  type        = string
  description = "Application name"
}

variable "clone_template_name" {
  type        = string
  description = "Clone Template name for deploy"
}

variable "vm_ssh_public_key" {
  type        = string
  default     = "id_rsa.pub"
  description = "Name of Public SSH key for VM"
}

variable "vm_init_script" {
  type        = string
  default     = "init.sh"
  description = "Name of init script for bootstrapping VM"
}

variable "virtual_machines" {
  description = "Map of Virtual Machines"
  type = map(object({
    target_node    = string
    memory         = number
    sockets        = number
    cores          = number
    storage        = string
    storage_size   = string
    storage_type   = string
    network_model  = string
    network_bridge = string
    ip             = string
    netmask        = string
    gateway        = string
    dns1           = string
    dns2           = string
    search_domain  = string
    disk = optional(map(object({
      size    = string
      storage = string
      type    = string
    })))
    additional_networks = optional(map(object({
      network_model  = string
      network_bridge = string
    })))
  }))
}

variable "data_disk" {
  description = "Additional data disk to VM (Data disk - /dev/sdb)"
  type = map(object({
    storage = string
    storage_size    = string
    storage_type    = string
    })
  )
  default = null
}

