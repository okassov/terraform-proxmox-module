provider "proxmox" {
  pm_api_url      = var.proxmox_api_url
  pm_user         = var.proxmox_api_user
  pm_password     = var.proxmox_api_pass
  pm_tls_insecure = var.proxmox_unverified_ssl
}

data "template_file" "cloud_init_template" {
  count = length(var.virtual_machines)

  template = file("${path.module}/files/cloud_init.tmpl")

  vars = {
    ssh_key        = file("${var.vm_ssh_public_key}")
    init_script    = file("${var.vm_init_script}")
    hostname       = keys(var.virtual_machines)[count.index]
    ip             = values(var.virtual_machines)[count.index]["ip"]
    netmask_prefix = values(var.virtual_machines)[count.index]["netmask"]
    gateway        = values(var.virtual_machines)[count.index]["gateway"]
    dns1           = values(var.virtual_machines)[count.index]["dns1"]
    dns2           = values(var.virtual_machines)[count.index]["dns2"]
    search_domain  = values(var.virtual_machines)[count.index]["search_domain"]
  }
}

resource "local_file" "user_data" {
  count = length(var.virtual_machines)

  content  = data.template_file.cloud_init_template[count.index].rendered
  filename = "${path.module}/files/user_data_${var.env}-${var.project}-${keys(var.virtual_machines)[count.index]}.yml"
}

resource "null_resource" "user_data_upload" {
  count = length(var.virtual_machines)

  depends_on = [
    local_file.user_data
  ]

  connection {
    type        = "ssh"
    user        = var.proxmox_ssh_user
    private_key = file("${var.proxmox_ssh_private_key}")
    host        = var.proxmox_ssh_host
    port        = var.proxmox_ssh_port
  }

  provisioner "remote-exec" {
    inline = ["sudo chmod 770 /var/lib/vz/snippets"]
  }

  provisioner "file" {
    source      = "${path.module}/files/user_data_${var.env}-${var.project}-${keys(var.virtual_machines)[count.index]}.yml"
    destination = "/var/lib/vz/snippets/user_data_${var.env}-${var.project}-${keys(var.virtual_machines)[count.index]}.yml"
  }
}

# Create the VM
resource "proxmox_vm_qemu" "virtualMachine" {
  for_each = var.virtual_machines

  depends_on = [
    null_resource.user_data_upload
  ]

  name                      = each.key
  target_node               = each.value.target_node
  clone                     = var.clone_template_name
  os_type                   = "cloud-init"
  cicustom                  = "user=local:snippets/user_data_${var.env}-${var.project}-${each.key}.yml"
  memory                    = each.value.memory
  sockets                   = each.value.sockets
  cores                     = each.value.cores
  agent                     = 0
  hotplug                   = "network,disk,cpu,memory,usb"
  guest_agent_ready_timeout = 90
  bootdisk                  = "scsi0"
  scsihw                    = "virtio-scsi-pci"

  disk {
    storage = each.value.storage
    size    = each.value.storage_size
    type    = each.value.storage_type
  }

  dynamic "disk" {

    for_each = var.data_disk != null ? var.data_disk : {}

    content {
      storage = values(var.data_disk)[0]["storage"]
      size    = values(var.data_disk)[0]["storage_size"]
      type    = values(var.data_disk)[0]["storage_type"]
    }
  }

  network {
    model  = each.value.network_model
    bridge = each.value.network_bridge
  }

  dynamic "network" {
    for_each = each.value.additional_networks != null ? each.value.additional_networks : {}

    content {
      model  = network.value.network_model
      bridge = network.value.network_bridge
    }
  }

  lifecycle {
    ignore_changes = [
      network
    ]
  }
}
