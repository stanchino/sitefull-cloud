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

        STORAGE_ACCOUNT_TYPE = 'Standard_LRS'.freeze

        private
        def network_interface_setup(subnet, security_group, public_ip, name)
          ip_configuration_props = NetworkInterfaceIPConfigurationPropertiesFormat.new
          ip_configuration_props.private_ipallocation_method = 'Dynamic'
          ip_configuration_props.subnet = subnet
          ip_configuration_props.public_ipaddress = public_ip

          ip_configuration = NetworkInterfaceIPConfiguration.new
          ip_configuration.name = name
          ip_configuration.properties = ip_configuration_props

          props = NetworkInterfacePropertiesFormat.new
          props.primary = true
          props.network_security_group = security_group
          props.ip_configurations = [ip_configuration]

          network_interface = NetworkInterface.new
          network_interface.location = options[:region]
          network_interface.name = name
          network_interface.properties = props

          connection.network.network_interfaces.create_or_update(resource_group_name, name, network_interface)
        end

        def public_ip_setup(name)
          dns_settings = PublicIPAddressDnsSettings.new
          dns_settings.domain_name_label = name

          props = PublicIPAddressPropertiesFormat.new
          props.public_ipallocation_method = 'Dynamic'
          props.dns_settings = dns_settings

          public_ip = PublicIPAddress.new
          public_ip.location = options[:region]
          public_ip.properties = props

          connection.network.public_ipaddresses.create_or_update(resource_group_name, name, public_ip)
        end

        def storage_setup(name)
          storage_account = connection.storage.storage_accounts.list_by_resource_group(resource_group_name).value!.body.value.find { |sa| sa.name == storage_account_name(name) }
          return storage_account unless storage_account.nil?

          properties = StorageAccountPropertiesCreateParameters.new
          properties.account_type = STORAGE_ACCOUNT_TYPE

          params = StorageAccountCreateParameters.new
          params.properties = properties
          params.location = options[:region]

          connection.storage.storage_accounts.create(resource_group_name, storage_account_name(name), params).value!.body
        end

        def instance_setup(storage, network_interface, machine_type, image, name)
          # Create a model for new virtual machine
          props = VirtualMachineProperties.new

          #windows_config = WindowsConfiguration.new
          #windows_config.provision_vmagent = true
          #windows_config.enable_automatic_updates = true
          linux_config = LinuxConfiguration.new
          linux_config.disable_password_authentication = false

          os_profile = OSProfile.new
          os_profile.computer_name = name
          os_profile.admin_username = 'sitefull'
          os_profile.admin_password = 'P@ssword1'
          os_profile.linux_configuration = linux_config
          # os_profile.custom_data = Base64.strict_encode64("#!/bin/sh\necho \"Hello World!\"").encode('utf-8')

          os_profile.secrets = []
          props.os_profile = os_profile

          hardware_profile = HardwareProfile.new
          hardware_profile.vm_size = machine_type
          props.hardware_profile = hardware_profile

          props.storage_profile = create_storage_profile(image, storage.name)

          network_profile = NetworkProfile.new
          network_profile.network_interfaces = [network_interface]
          props.network_profile = network_profile

          params = VirtualMachine.new
          params.type = 'Microsoft.Compute/virtualMachines'
          params.properties = props
          params.location = options[:region]

          connection.compute.virtual_machines.create_or_update(resource_group_name, name, params)
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
