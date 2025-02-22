Vagrant.configure("2") do |config|
  # Configure VM
  config.vm.box = "debian12-arm64"
  config.vm.box_url = ENV['BOX_URL'] || "/tmp/packer_cache/out/packer_debian_vmware_arm64.box"

  # Configure VMware provider
  config.vm.provider "vmware_desktop" do |vmware|
    vmware.gui = true
    vmware.vmx["ethernet0.virtualdev"] = "vmxnet3"
    vmware.vmx["memsize"] = ENV['VM_MEMORY'] || "2048"
    vmware.vmx["numvcpus"] = ENV['VM_CPUS'] || "2"
  end

  # Configure synced folder
  config.vm.synced_folder ".", "/vagrant", create: true

  # Basic system update and Ansible installation
  config.vm.provision "shell", inline: <<-SHELL
    apt-get update
    apt-get upgrade -y
    apt-get install -y ansible
  SHELL

  # Ansible provisioning
  config.vm.provision "ansible_local" do |ansible|
    ansible.playbook = "playbook.yaml"
    ansible.compatibility_mode = "2.0"
    ansible.become = true
    ansible.extra_vars = {
      ansible_python_interpreter: "/usr/bin/python3"
    }
  end
end 