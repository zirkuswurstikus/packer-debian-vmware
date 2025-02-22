variable "user_name" {
  type = string
  default = "vagrant"
}

variable "user_pwd" {
  type = string
  default = "vagrant"
}

variable "packer_cache_dir" {
  type = string
  default = "/tmp/packer_cache"
}

variable "out_dir" {
  type = string
  default = "/tmp/packer_cache/out"
}

variable "iso_url" {
  type = string
  default = "https://cdimage.debian.org/debian-cd/current/arm64/iso-cd/debian-12.9.0-arm64-netinst.iso"
}

variable "iso_checksum" {
  type = string
  default = "sha512:04a2a128852c2dff8bb71779ad325721385051eb1264d897bdb5918ab207a9b1de636ded149c56c61a09eb8c7f428496815e70d3be31b1b1cf4c70bf6427cedd"
}

variable "vm_cpus" {
  type = number
  default = 2
}

variable "vm_memory" {
  type = number
  default = 2048
}

variable "vm_disk_size" {
  type = number
  default = 20480
}

# VM name as shown in VMware Fusion
variable "vm_name" {
  type = string
  default = "Debian 12.9 (arm64)"
}

packer {
  required_version = "= 1.11.2"
  required_plugins {
    vmware = {
      version = "= 1.1.0"
      source  = "github.com/hashicorp/vmware"
    }
    vagrant = {
      version = "= 1.1.5"
      source  = "github.com/hashicorp/vagrant"
    }
  }
}

source "vmware-iso" "debian" {
  iso_url           = var.iso_url
  iso_checksum      = var.iso_checksum
  ssh_username      = var.user_name
  ssh_password      = var.user_pwd
  ssh_timeout       = "10m"
  shutdown_command  = "echo '${var.user_pwd}' | sudo -S shutdown -P now"
  guest_os_type     = "arm-debian12-64"
  disk_adapter_type = "nvme"
  version           = 20
  http_directory    = "http"
  boot_command = [
    "c",
    "linux /install.a64/vmlinuz",
    " auto-install/enable=true",
    " debconf/priority=critical",
    " netcfg/hostname=debian-12",
    " netcfg/get_domain=",
    " preseed/url=http://{{ .HTTPIP }}:{{ .HTTPPort }}/preseed.cfg --- quiet",
    "<enter>",
    "initrd /install.a64/initrd.gz",
    "<enter>",
    "boot",
    "<enter><wait>"
  ]
  memory               = var.vm_memory
  cpus                 = var.vm_cpus
  disk_size            = var.vm_disk_size
  vm_name              = var.vm_name
  network_adapter_type = "vmxnet3"
  output_directory     = "${var.packer_cache_dir}/vmware"
  usb                  = true
  vmx_data = {
    "usb_xhci.present" = "true"
    "ethernet0.virtualdev" = "vmxnet3"
    "virtualHW.version" = "20"
    "firmware" = "efi"
  }
  vnc_bind_address = "127.0.0.1"
  vnc_port_min = 5900
  vnc_port_max = 5900
  vmx_data_post = {
    "cpuid.coresPerSocket" = "1"
    "tools.upgrade.policy" = "manual"
  }
  fusion_app_path = "/Applications/VMware Fusion.app"
}

build {
  name    = "debian-vmware"
  sources = ["sources.vmware-iso.debian"]

  provisioner "shell" {
    execute_command = "echo '${var.user_pwd}' | {{ .Vars }} sudo -E -S sh '{{ .Path }}'"
    inline = ["echo '%sudo    ALL=(ALL)  NOPASSWD:ALL' >> /etc/sudoers"]
  }

  provisioner "shell" {
    environment_vars = [
      "USER_NAME=${var.user_name}",
      "VMWARE=1"
    ]
    scripts = [
      "scripts/create-user.sh",
      "scripts/disable-ipv6.sh",
      "scripts/install.sh"
    ]
  }

  post-processor "vagrant" {
    compression_level              = 9
    vagrantfile_template_generated = true
    output                        = "${var.out_dir}/packer_{{.BuildName}}_{{.Provider}}_{{.Architecture}}.box"
  }
}
