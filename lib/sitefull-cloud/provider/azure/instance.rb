require 'azure_mgmt_compute'
require 'azure_mgmt_network'
require 'azure_mgmt_storage'

module Sitefull
  module Provider
    module Azure
      module Instance
        include ::Azure::ARM::Compute::Models
        include ::Azure::ARM::Network::Models
        include ::Azure::ARM::Storage::Models


        private

        def network_interface_setup(subnet, security_group, public_ip, name)
          ip_configuration = NetworkInterfaceIPConfiguration.new
          ip_configuration.name = name
          ip_configuration.private_ipallocation_method = 'Dynamic'
          ip_configuration.subnet = subnet
          ip_configuration.public_ipaddress = public_ip

          network_interface = NetworkInterface.new
          network_interface.location = options[:region]
          network_interface.name = name
          network_interface.primary = true
          network_interface.network_security_group = security_group
          network_interface.ip_configurations = [ip_configuration]

          connection.network.network_interfaces.create_or_update(resource_group_name, name, network_interface)
        end

        def public_ip_setup(name)
          dns_settings = PublicIPAddressDnsSettings.new
          dns_settings.domain_name_label = name

          public_ip = PublicIPAddress.new
          public_ip.public_ipallocation_method = 'Dynamic'
          public_ip.location = options[:region]

          connection.network.public_ipaddresses.create_or_update(resource_group_name, name, public_ip)
        end

        def public_ip(name)
          connection.network.public_ipaddresses.get(resource_group_name, name).properties.ip_address
        end

        def storage_setup(name)
          storage_account = storage_account(name)
          return storage_account unless storage_account.nil?

          sku = Sku.new
          sku.name = 'Standard_LRS'
          sku.tier = 'Standard'

          params = StorageAccountCreateParameters.new
          params.sku = sku
          params.kind = 'Storage'
          params.location = options[:region]

          connection.storage.storage_accounts.create(resource_group_name, storage_account_name(name), params).value!.body
        end

        def storage_account(name)
          connection.storage.storage_accounts.list_by_resource_group(resource_group_name).value.find { |sa| sa.name == storage_account_name(name) }
        end

        def instance_setup(storage, network_interface, instance_data)
          # Create a model for new virtual machine
          #
          #windows_config = WindowsConfiguration.new
          #windows_config.provision_vmagent = true
          #windows_config.enable_automatic_updates = true

          ssh_key = SshPublicKey.new
          ssh_key.path = "/home/#{instance_data[:key].ssh_user}/.ssh/authorized_keys"
          ssh_key.key_data = "ssh-rsa #{instance_data[:key].public_key} #{instance_data[:key].ssh_user}"

          ssh_config = SshConfiguration.new
          ssh_config.public_keys = [ssh_key]

          linux_config = LinuxConfiguration.new
          linux_config.ssh = ssh_config
          linux_config.disable_password_authentication = true

          os_profile = OSProfile.new
          os_profile.computer_name = instance_data[:name]
          os_profile.admin_username = instance_data[:key].ssh_user
          os_profile.linux_configuration = linux_config


          hardware_profile = HardwareProfile.new
          hardware_profile.vm_size = instance_data[:machine_type]

          network_profile = NetworkProfile.new
          network_profile.network_interfaces = [network_interface]

          params = VirtualMachine.new
          params.type = 'Microsoft.Compute/virtualMachines'
          params.os_profile = os_profile
          params.network_profile = network_profile
          params.hardware_profile = hardware_profile
          params.storage_profile = create_storage_profile(instance_data[:image], storage.name)
          params.location = options[:region]

          connection.compute.virtual_machines.create_or_update(resource_group_name, instance_data[:name], params)
        end

        def instance(instance_id)
          connection.compute.virtual_machines.get(resource_group_name, instance_id)
        end

        def create_storage_profile(image, name)
          storage_profile = StorageProfile.new
          storage_profile.image_reference = get_image_reference(image)

          os_disk = OSDisk.new
          os_disk.caching = 'ReadWrite'
          os_disk.create_option = 'FromImage'
          os_disk.name = name

          virtual_hard_disk = VirtualHardDisk.new
          virtual_hard_disk.uri = "https://#{name}.blob.core.windows.net/vhds/os.vhd"

          os_disk.vhd = virtual_hard_disk
          storage_profile.os_disk = os_disk

          storage_profile
        end

        def get_image_reference(image)
          publisher, offer, sku = image.split(':')
          image_reference = ImageReference.new
          image_reference.publisher = publisher
          image_reference.offer = offer
          image_reference.sku = sku
          image_reference.version = 'latest'
          image_reference
        end

        def storage_account_name(name)
          @storage_account_name ||= Digest::MD5.hexdigest("#{resource_group_name}:#{name}")[0..23]
        end
      end
    end
  end
end
