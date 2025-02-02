variable "disk_size" {
  type    = string
  default = "8192"
}

variable "version" {
  type = string
}

variable "vsphere_host" {
  type    = string
  default = env("GOVC_HOST")
}

variable "vsphere_username" {
  type    = string
  default = env("GOVC_USERNAME")
}

variable "vsphere_password" {
  type      = string
  default   = env("GOVC_PASSWORD")
  sensitive = true
}

variable "vsphere_esxi_host" {
  type    = string
  default = env("VSPHERE_ESXI_HOST")
}

variable "vsphere_datacenter" {
  type    = string
  default = env("GOVC_DATACENTER")
}

variable "vsphere_cluster" {
  type    = string
  default = env("GOVC_CLUSTER")
}

variable "vsphere_datastore" {
  type    = string
  default = env("GOVC_DATASTORE")
}

variable "vsphere_folder" {
  type    = string
  default = env("VSPHERE_TEMPLATE_FOLDER")
}

variable "vsphere_template_name" {
  type    = string
  default = env("VSPHERE_TEMPLATE_NAME")
}

variable "vsphere_network" {
  type    = string
  default = env("VSPHERE_VLAN")
}

variable "vsphere_ip_wait_address" {
  type        = string
  default     = env("VSPHERE_IP_WAIT_ADDRESS")
  description = "IP CIDR which guests will use to reach the host. see https://github.com/hashicorp/packer/blob/ff5b55b560095ca88421d3f1ad8b8a66646b7ab6/builder/vsphere/common/step_http_ip_discover.go#L32"
}

variable "vsphere_os_iso" {
  type        = string
  default     = env("VSPHERE_OS_ISO")
}

source "vsphere-iso" "ubuntu-amd64" {
  CPUs     = 4
  RAM      = 2048
  cd_label = "cidata"
  cd_files = [
    "tmp/vsphere-autoinstall-cloud-init-data/user-data",
    "autoinstall-cloud-init-data/meta-data"
  ]
  boot_command = [
    "e",
    "<leftCtrlOn>kkkkkkkkkkkkkkkkkkkk<leftCtrlOff>",
    "linux /casper/vmlinuz",
    " net.ifnames=0",
    " autoinstall",
    "<enter>",
    "initrd /casper/initrd",
    "<enter>",
    "<f10>",
  ]
  boot_wait           = "5s"
  convert_to_template = true
  insecure_connection = true
  vcenter_server      = var.vsphere_host
  username            = var.vsphere_username
  password            = var.vsphere_password
  vm_name             = "${var.vsphere_template_name}"
  datacenter          = var.vsphere_datacenter
  cluster             = var.vsphere_cluster
  host                = var.vsphere_esxi_host
  folder              = var.vsphere_folder
  datastore           = var.vsphere_datastore
  guest_os_type       = "ubuntu64Guest"
  ip_wait_address     = var.vsphere_ip_wait_address
  iso_paths = [
    var.vsphere_os_iso
  ]
  network_adapters {
    network      = var.vsphere_network
    network_card = "vmxnet3"
  }
  storage {
    disk_size             = var.disk_size
    disk_thin_provisioned = true
  }
  disk_controller_type = ["pvscsi"]
  ssh_password         = "vagrant"
  ssh_username         = "vagrant"
  ssh_timeout          = "60m"
  shutdown_command     = "sudo -S poweroff"
}

build {
  sources = ["source.vsphere-iso.ubuntu-amd64"]

  provisioner "shell" {
    execute_command = "echo vagrant | sudo -S {{ .Vars }} bash {{ .Path }}"
    scripts = [
      "upgrade.sh",
    ]
  }

  provisioner "shell" {
    execute_command = "sudo -S {{ .Vars }} bash {{ .Path }}"
    expect_disconnect = true
    scripts = [
      "reboot.sh",
    ]
  }

  provisioner "shell" {
    execute_command = "sudo -S {{ .Vars }} bash {{ .Path }}"
    scripts = [
      "provision-guest-additions.sh",
    ]
  }

  provisioner "shell" {
    execute_command = "sudo -S {{ .Vars }} bash {{ .Path }}"
    expect_disconnect = true
    scripts = [
      "reboot.sh",
    ]
  }

  provisioner "shell" {
    execute_command = "sudo -S {{ .Vars }} bash {{ .Path }}"
    scripts = [
      "provision.sh",
    ]
  }
}
