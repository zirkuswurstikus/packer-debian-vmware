# Cache and output directories
PACKER_CACHE_DIR := /tmp/packer_cache
OUT_DIR := $(PACKER_CACHE_DIR)/out

# VM configuration
VM_NAME := "Packer_Debian_12.9_arm64" # no whitespace
VM_CPUS := 8
VM_MEMORY := 2048

# ISO configuration
# Netinstall ISO
ISO_URL := "https://cdimage.debian.org/debian-cd/current/arm64/iso-cd/debian-12.9.0-arm64-netinst.iso"
ISO_CHECKSUM := "sha512:04a2a128852c2dff8bb71779ad325721385051eb1264d897bdb5918ab207a9b1de636ded149c56c61a09eb8c7f428496815e70d3be31b1b1cf4c70bf6427cedd"

# Box configuration
BOX_NAME := debian12-arm64
BOX_URL := $(OUT_DIR)/packer_debian_vmware_arm64.box

# Required paths
VMWARE_FUSION_APP := "/Applications/VMware Fusion.app"

.PHONY: all build test clean init check-vmware

all: build test
	@echo "All tasks completed successfully"

check-vmware:
	@echo "Checking VMware Fusion installation..."
	@test -d $(VMWARE_FUSION_APP) || (echo "Error: VMware Fusion not found at $(VMWARE_FUSION_APP)" && exit 1)

init: check-vmware
	@echo "Initializing Packer..."
	packer init .

build: clean init
	@echo "Building VMware box..."
	packer build \
		-var "packer_cache_dir=$(PACKER_CACHE_DIR)" \
		-var "out_dir=$(OUT_DIR)" \
		-var "vm_name=$(VM_NAME)" \
		-var "vm_cpus=$(VM_CPUS)" \
		-var "vm_memory=$(VM_MEMORY)" \
		-var "iso_url=$(ISO_URL)" \
		-var "iso_checksum=$(ISO_CHECKSUM)" \
		.

test:
	@echo "Testing VMware box..."
	BOX_URL=$(BOX_URL) VM_CPUS=$(VM_CPUS) VM_MEMORY=$(VM_MEMORY) vagrant up --provider vmware_desktop
	vagrant ssh -c "sudo whoami" | grep "root"
	vagrant destroy -f
	@echo "VMware box test completed successfully"

clean:
	@echo "Cleaning up..."
	rm -rf $(OUT_DIR)
	rm -rf $(PACKER_CACHE_DIR)/vmware
	vagrant box remove -f $(BOX_NAME) || true 
