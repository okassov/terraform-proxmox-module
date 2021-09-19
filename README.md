# Terraform custom module (Proxmox)

This custom module automating creation of Virtual Machnine in Proxmox.

## Prerequisits

 - terraform  >= 1.0.4
 - vmware/vcd >= 2.7.4
 
## How to use module

 - Install terragrunt
 - Source this module in terragrunt.hcl
 - Run terragrunt

### Example of default project structure

```
project-name/
  |__dev/
       |__terragrunt.hcl
       |__mongodb/
            |__terragrunt.hcl
  |__stage/
       |__terragrunt.hcl
       |__mongodb/
            |__terragrunt.hcl
  |__prod/
       |__terragrunt.hcl
       |__mongodb/
            |__terragrunt.hcl
```

### Example of environment terragrunt.hcl

```
remote_state {
  backend = "s3"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
  config = {
    bucket = "terraform-dev-state"
    key    = "${path_relative_to_include()}/terraform.tfstate"
    region = "us-east-1"
    access_key = "changeme"
    secret_key = "changeme"
    endpoint = "https://s3.example.com"
    skip_credentials_validation = true
    force_path_style = true
  }
}

locals {
  proxmox_api_url  = "https://proxmox.example.com:8006/api2/json"
  proxmox_api_user = "root@pam"
  proxmox_api_pass = "changeme"
  proxmox_ssh_host = "proxmox.example.com"
  proxmox_ssh_user = "root"

  env = "dev"
}
```

### Example of terragrunt.hcl for create single VM

```
terraform {
  source = "github.com/okassov/terraform-proxmox-module.git?ref=v1.0.0"
}

include {
  path = find_in_parent_folders()
}

locals {
  common_vars = read_terragrunt_config(find_in_parent_folders())
}

inputs = {
  proxmox_api_url  = local.common_vars.locals.proxmox_api_url
  proxmox_api_user = local.common_vars.locals.proxmox_api_user
  proxmox_api_pass = local.common_vars.locals.proxmox_api_pass
  proxmox_ssh_host = local.common_vars.locals.proxmox_ssh_host
  proxmox_ssh_user = local.common_vars.locals.proxmox_ssh_user
  
  env = local.common_vars.locals.env
  
  project = "test-project"
  role = "db"
  app = "mongo"

  clone_template_name = "test_template"

  virtual_machines = {
    mongo-01 = {
      target_node    = "ds"
      memory         = 2048
      sockets        = 1
      cores          = 1
      storage        = "vmdata"
      storage_size   = "32G"
      storage_type   = "scsi"
      network_model  = "virtio"
      network_bridge = "vmbr1"
      ip             = "172.16.1.213"
      netmask        = "24"
      gateway        = "172.16.1.1"
      dns1           = "8.8.8.8"
      dns2           = "1.1.1.1"
      search_domain  = "example.com"
    },
  }
}
```

### Example of terragrunt.hcl for create multiple VM

> Note: then you provision multiple VMs, you must add "-parallelism=1" option, because Proxmox cannot clone multiple VM from one template at the same time

Provision example:
```
terragrunt apply -parallelism=1
```

```
terraform {
  source = "github.com/okassov/terraform-proxmox-module.git?ref=v1.0.0"
}

include {
  path = find_in_parent_folders()
}

locals {
  common_vars = read_terragrunt_config(find_in_parent_folders())
}

inputs = {
  proxmox_api_url  = local.common_vars.locals.proxmox_api_url
  proxmox_api_user = local.common_vars.locals.proxmox_api_user
  proxmox_api_pass = local.common_vars.locals.proxmox_api_pass
  proxmox_ssh_host = local.common_vars.locals.proxmox_ssh_host
  proxmox_ssh_user = local.common_vars.locals.proxmox_ssh_user
  
  env = local.common_vars.locals.env
  
  project = "test-project"
  role = "db"
  app = "mongo"

  clone_template_name = "test_template"

  virtual_machines = {
    mongo-01 = {
      target_node    = "ds"
      memory         = 2048
      sockets        = 1
      cores          = 1
      storage        = "vmdata"
      storage_size   = "32G"
      storage_type   = "scsi"
      network_model  = "virtio"
      network_bridge = "vmbr1"
      ip             = "172.16.1.213"
      netmask        = "24"
      gateway        = "172.16.1.1"
      dns1           = "8.8.8.8"
      dns2           = "1.1.1.1"
      search_domain  = "example.com"
    },
    mongo-02 = {
      target_node    = "ds"
      memory         = 2048
      sockets        = 1
      cores          = 1
      storage        = "vmdata"
      storage_size   = "32G"
      storage_type   = "scsi"
      network_model  = "virtio"
      network_bridge = "vmbr1"
      ip             = "172.16.1.214"
      netmask        = "24"
      gateway        = "172.16.1.1"
      dns1           = "8.8.8.8"
      dns2           = "1.1.1.1"
      search_domain  = "example.com"
    },
    mongo-03 = {
      target_node    = "ds"
      memory         = 2048
      sockets        = 1
      cores          = 1
      storage        = "vmdata"
      storage_size   = "32G"
      storage_type   = "scsi"
      network_model  = "virtio"
      network_bridge = "vmbr1"
      ip             = "172.16.1.215"
      netmask        = "24"
      gateway        = "172.16.1.1"
      dns1           = "8.8.8.8"
      dns2           = "1.1.1.1"
      search_domain  = "example.com"
    },
  }
}
```


### Example of terragrunt.hcl for create multiple VM with independent external disk

In this example we have new variable ***data_disk***. For each VM will be created second external data disk.

```
terraform {
  source = "github.com/okassov/terraform-proxmox-module.git?ref=v1.0.0"
}

include {
  path = find_in_parent_folders()
}

locals {
  common_vars = read_terragrunt_config(find_in_parent_folders())
}

inputs = {
  proxmox_api_url  = local.common_vars.locals.proxmox_api_url
  proxmox_api_user = local.common_vars.locals.proxmox_api_user
  proxmox_api_pass = local.common_vars.locals.proxmox_api_pass
  proxmox_ssh_host = local.common_vars.locals.proxmox_ssh_host
  proxmox_ssh_user = local.common_vars.locals.proxmox_ssh_user
  
  env = local.common_vars.locals.env
  
  project = "test-project"
  role = "db"
  app = "mongo"

  clone_template_name = "test_template"

  data_disk = {
    data = {
      storage         = "vmdata"
      storage_size    = "50G"
      storage_type    = "scsi"
    }
  }

  virtual_machines = {
    mongo-01 = {
      target_node    = "ds"
      memory         = 2048
      sockets        = 1
      cores          = 1
      storage        = "vmdata"
      storage_size   = "32G"
      storage_type   = "scsi"
      network_model  = "virtio"
      network_bridge = "vmbr1"
      ip             = "172.16.1.213"
      netmask        = "24"
      gateway        = "172.16.1.1"
      dns1           = "8.8.8.8"
      dns2           = "1.1.1.1"
      search_domain  = "example.com"
    },
    mongo-02 = {
      target_node    = "ds"
      memory         = 2048
      sockets        = 1
      cores          = 1
      storage        = "vmdata"
      storage_size   = "32G"
      storage_type   = "scsi"
      network_model  = "virtio"
      network_bridge = "vmbr1"
      ip             = "172.16.1.214"
      netmask        = "24"
      gateway        = "172.16.1.1"
      dns1           = "8.8.8.8"
      dns2           = "1.1.1.1"
      search_domain  = "example.com"
    },
    mongo-03 = {
      target_node    = "ds"
      memory         = 2048
      sockets        = 1
      cores          = 1
      storage        = "vmdata"
      storage_size   = "32G"
      storage_type   = "scsi"
      network_model  = "virtio"
      network_bridge = "vmbr1"
      ip             = "172.16.1.215"
      netmask        = "24"
      gateway        = "172.16.1.1"
      dns1           = "8.8.8.8"
      dns2           = "1.1.1.1"
      search_domain  = "example.com"
    },
  }
}
```

### Example of terragrunt.hcl for create VM with additional network interface

```
terraform {
  source = "github.com/okassov/terraform-proxmox-module.git?ref=v1.0.0"
}

include {
  path = find_in_parent_folders()
}

locals {
  common_vars = read_terragrunt_config(find_in_parent_folders())
}

inputs = {
  proxmox_api_url  = local.common_vars.locals.proxmox_api_url
  proxmox_api_user = local.common_vars.locals.proxmox_api_user
  proxmox_api_pass = local.common_vars.locals.proxmox_api_pass
  proxmox_ssh_host = local.common_vars.locals.proxmox_ssh_host
  proxmox_ssh_user = local.common_vars.locals.proxmox_ssh_user
  
  env = local.common_vars.locals.env
  
  project = "test-project"
  role = "db"
  app = "mongo"

  clone_template_name = "test_template"

  virtual_machines = {
    mongo-01 = {
      target_node    = "ds"
      memory         = 2048
      sockets        = 1
      cores          = 1
      storage        = "vmdata"
      storage_size   = "32G"
      storage_type   = "scsi"
      network_model  = "virtio"
      network_bridge = "vmbr1"
      ip             = "172.16.1.213"
      netmask        = "24"
      gateway        = "172.16.1.1"
      dns1           = "8.8.8.8"
      dns2           = "1.1.1.1"
      search_domain  = "example.com"
      additional_networks = {
        second_nic = {
          network_model  = "virtio"
          network_bridge = "vmbr1"
        }
      }
    },
  }
}
```
