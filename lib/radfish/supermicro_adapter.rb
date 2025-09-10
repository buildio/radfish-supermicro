# frozen_string_literal: true

require 'supermicro'
require 'ostruct'

module Radfish
  class SupermicroAdapter < Core::BaseClient
    include Core::Power
    include Core::System
    include Core::Storage
    include Core::VirtualMedia
    include Core::Boot
    include Core::Jobs
    include Core::Utility
    include Core::Network
    
    attr_reader :supermicro_client
    
    def initialize(host:, username:, password:, **options)
      super
      
      # Create the underlying Supermicro client
      @supermicro_client = ::Supermicro::Client.new(
        host: host,
        username: username,
        password: password,
        port: options[:port] || 443,
        use_ssl: options.fetch(:use_ssl, true),
        verify_ssl: options.fetch(:verify_ssl, false),
        direct_mode: options.fetch(:direct_mode, false),
        retry_count: options[:retry_count] || 3,
        retry_delay: options[:retry_delay] || 1,
        host_header: options[:host_header]
      )
    end
    
    def vendor
      'supermicro'
    end
    
    def verbosity=(value)
      super
      @supermicro_client.verbosity = value if @supermicro_client
    end
    
    # Session management
    
    def login
      @supermicro_client.login
    end
    
    def logout
      @supermicro_client.logout
    end
    
    def authenticated_request(method, path, **options)
      @supermicro_client.authenticated_request(method, path, **options)
    end
    
    # Power management
    
    def power_status
      @supermicro_client.power_status
    end
    
    def power_on(wait: true)
      result = @supermicro_client.power_on
      
      if wait && result
        # Wait for power on to complete
        max_attempts = 30
        attempts = 0
        while attempts < max_attempts
          sleep 2
          begin
            status = @supermicro_client.power_status
            break if status == "On"
          rescue => e
            # BMC might be temporarily unavailable during power operations
            debug "Waiting for BMC to respond: #{e.message}", 1, :yellow
          end
          attempts += 1
        end
      end
      
      result
    end
    
    def power_off(type: "GracefulShutdown", wait: true)
      # Translate Redfish standard types to Supermicro's force parameter
      force = (type == "ForceOff")
      result = @supermicro_client.power_off(force: force)
      
      if wait && result
        # Wait for power off to complete
        max_attempts = 30
        attempts = 0
        while attempts < max_attempts
          sleep 2
          begin
            status = @supermicro_client.power_status
            break if status == "Off"
          rescue => e
            # BMC might be temporarily unavailable during power operations
            debug "Waiting for BMC to respond: #{e.message}", 1, :yellow
          end
          attempts += 1
        end
      end
      
      result
    end
    
    def reboot(type: "GracefulRestart", wait: true)
      # Translate Redfish standard types to Supermicro's force parameter
      force = (type == "ForceRestart")
      result = @supermicro_client.power_restart(force: force)
      
      if wait && result
        # Wait for system to go down then come back up
        max_attempts = 60
        attempts = 0
        went_down = false
        
        while attempts < max_attempts
          sleep 2
          begin
            status = @supermicro_client.power_status
            went_down = true if status == "Off" && !went_down
            break if went_down && status == "On"
          rescue => e
            # BMC might be temporarily unavailable during reboot
            debug "Waiting for BMC during reboot: #{e.message}", 1, :yellow
          end
          attempts += 1
        end
      end
      
      result
    end
    
    def power_cycle(wait: true)
      result = @supermicro_client.power_cycle
      
      if wait && result
        # Wait for system to go down then come back up
        max_attempts = 60
        attempts = 0
        went_down = false
        
        while attempts < max_attempts
          sleep 2
          begin
            status = @supermicro_client.power_status
            went_down = true if status == "Off" && !went_down
            break if went_down && status == "On"
          rescue => e
            # BMC might be temporarily unavailable during power cycle
            debug "Waiting for BMC during power cycle: #{e.message}", 1, :yellow
          end
          attempts += 1
        end
      end
      
      result
    end
    
    def reset_type_allowed
      @supermicro_client.reset_type_allowed
    end
    
    # System information
    
    def system_info
      # Supermicro gem returns string keys, convert to symbols for radfish
      info = @supermicro_client.system_info
      
      # Use minimal naming approach for consistency across systems
      # Normalize manufacturer/make to just "Supermicro"
      manufacturer = info["manufacturer"]
      if manufacturer
        # Strip "Super Micro", "Super Micro Computer", etc. to just "Supermicro"
        manufacturer = manufacturer.gsub(/Super\s*Micro(\s+Computer.*)?/i, 'Supermicro')
      end
      
      # Extract service tag from Manager UUID (BMC MAC address)
      # Manager UUID format: 00000000-0000-0000-0000-XXXXXXXXXXXX
      # Service tag is the last XXXXXXXXXXXX part (BMC MAC without colons)
      service_tag = info["manager_uuid"]&.split('-')&.last || info["serial"]
      
      {
        service_tag: service_tag,  # Last block of UUID or fallback to serial
        manufacturer: manufacturer,
        make: manufacturer,
        model: info["model"],
        serial: info["serial"],
        serial_number: info["serial"],
        name: info["name"],
        uuid: info["uuid"],
        bios_version: info["bios_version"],
        power_state: info["power_state"],
        health: info["health"]
      }.compact
    end
    
    # Individual accessor methods for Core::System interface
    def service_tag
      @service_tag ||= begin
        info = @supermicro_client.system_info
        info["manager_uuid"]&.split('-')&.last || info["serial"]
      end
    end
    
    def make
      @make ||= begin
        info = @supermicro_client.system_info
        manufacturer = info["manufacturer"]
        if manufacturer
          # Strip "Super Micro", "Super Micro Computer", etc. to just "Supermicro"
          manufacturer.gsub(/Super\s*Micro(\s+Computer.*)?/i, 'Supermicro')
        else
          "Supermicro"
        end
      end
    end
    
    def model
      @model ||= @supermicro_client.system_info["model"]
    end
    
    def serial
      @serial ||= @supermicro_client.system_info["serial"]
    end
    
    def cpus
      # The supermicro gem returns an array of CPU hashes
      # Convert them to OpenStruct objects for dot notation access
      cpu_data = @supermicro_client.cpus
      
      cpu_data.map do |cpu|
        OpenStruct.new(
          socket: cpu["socket"],
          manufacturer: cpu["manufacturer"],
          model: cpu["model"],
          speed_mhz: cpu["speed_mhz"],
          cores: cpu["cores"],
          threads: cpu["threads"],
          health: cpu["health"]
        )
      end
    end
    
    def memory
      mem_data = @supermicro_client.memory
      return [] unless mem_data
      
      # Convert to OpenStruct for dot notation access
      mem_data.map { |m| OpenStruct.new(m) }
    end
    
    def nics
      nic_data = @supermicro_client.nics
      return [] unless nic_data
      
      # Convert to OpenStruct for dot notation access, including nested ports
      nic_data.map do |nic|
        if nic["ports"]
          nic["ports"] = nic["ports"].map { |port| OpenStruct.new(port) }
        end
        OpenStruct.new(nic)
      end
    end
    
    def fans
      # Convert hash array to OpenStruct objects for dot notation access
      fan_data = @supermicro_client.fans
      
      fan_data.map do |fan|
        OpenStruct.new(fan)
      end
    end
    
    def temperatures
      # Supermicro doesn't provide a dedicated temperatures method
      # Return empty array to satisfy the interface
      []
    end
    
    def psus
      # Convert hash array to OpenStruct objects for dot notation access
      psu_data = @supermicro_client.psus
      
      psu_data.map do |psu|
        OpenStruct.new(psu)
      end
    end
    
    def power_consumption
      @supermicro_client.power_consumption
    end
    
    def power_consumption_watts
      # Extract just the current watts from the power_consumption hash
      data = @supermicro_client.power_consumption
      data["consumed_watts"] if data.is_a?(Hash)
    end
    
    # Storage
    
    def storage_controllers
      # Convert hash array to OpenStruct objects for dot notation access
      controller_data = @supermicro_client.storage_controllers
      
      controller_data.map do |controller|
        # Convert drives array to OpenStruct objects if present
        if controller["drives"]
          controller["drives"] = controller["drives"].map { |drive| OpenStruct.new(drive) }
        end
        OpenStruct.new(controller)
      end
    end
    
    def drives(controller_id)
      # The Supermicro gem now requires controller_id following natural Redfish pattern
      raise ArgumentError, "Controller ID is required" unless controller_id
      
      drive_data = @supermicro_client.drives(controller_id)
      
      # Convert to OpenStruct for consistency
      drive_data.map { |drive| OpenStruct.new(drive) }
    end
    
    def volumes(controller_id)
      # The Supermicro gem now requires controller_id following natural Redfish pattern
      raise ArgumentError, "Controller ID is required" unless controller_id
      
      volume_data = @supermicro_client.volumes(controller_id)
      
      # Convert to OpenStruct for consistency
      volume_data.map { |volume| OpenStruct.new(volume) }
    end
    
    def storage_summary
      @supermicro_client.storage_summary
    end
    
    # Virtual Media
    
    def virtual_media
      @supermicro_client.virtual_media
    end
    
    def insert_virtual_media(iso_url, device: nil)
      @supermicro_client.insert_virtual_media(iso_url, device: device)
    rescue Supermicro::Error => e
      # Translate Supermicro errors to Radfish errors with context
      error_message = e.message
      
      if error_message.include?("connection refused") || error_message.include?("port number")
        raise Radfish::VirtualMediaConnectionError, "BMC cannot reach ISO server: #{error_message}"
      elsif error_message.include?("NotConnected") || error_message.include?("not connected")
        raise Radfish::VirtualMediaConnectionError, "Virtual media failed to connect properly: #{error_message}"
      elsif error_message.include?("license") || error_message.include?("SFT-OOB-LIC")
        raise Radfish::VirtualMediaLicenseError, "Virtual media license required: #{error_message}"
      elsif error_message.include?("already inserted") || error_message.include?("busy")
        raise Radfish::VirtualMediaBusyError, "Virtual media device busy: #{error_message}"
      elsif error_message.include?("not found") || error_message.include?("No suitable")
        raise Radfish::VirtualMediaNotFoundError, "Virtual media device not found: #{error_message}"
      elsif error_message.include?("timeout")
        raise Radfish::TaskTimeoutError, "Virtual media operation timed out: #{error_message}"
      else
        # Generic virtual media error
        raise Radfish::VirtualMediaError, error_message
      end
    end
    
    def eject_virtual_media(device: nil)
      @supermicro_client.eject_virtual_media(device: device)
    rescue Supermicro::Error => e
      # Translate errors consistently
      if e.message.include?("not found") || e.message.include?("No suitable")
        raise Radfish::VirtualMediaNotFoundError, "Virtual media device not found: #{e.message}"
      else
        raise Radfish::VirtualMediaError, "Failed to eject virtual media: #{e.message}"
      end
    end
    
    def virtual_media_status
      @supermicro_client.virtual_media_status
    end
    
    def mount_iso_and_boot(iso_url, device: nil)
      @supermicro_client.mount_iso_and_boot(iso_url, device: device)
    end
    
    def unmount_all_media
      @supermicro_client.unmount_all_media
    end
    
    # Boot configuration
    
    def boot_config
      # Return hash for consistent data structure
      @supermicro_client.boot_config
    end
    
    # Shorter alias for convenience
    def boot
      boot_config
    end
    
    def boot_options
      # Return array of OpenStructs for boot options
      options = @supermicro_client.boot_options
      options.map { |opt| OpenStruct.new(opt) }
    end
    
    def set_boot_override(target, enabled: "Once", mode: nil)
      @supermicro_client.set_boot_override(target, enabled: enabled, mode: mode)
    end
    
    def clear_boot_override
      @supermicro_client.clear_boot_override
    end
    
    def set_boot_order(devices)
      @supermicro_client.set_boot_order(devices)
    end
    
    def get_boot_devices
      @supermicro_client.get_boot_devices
    end
    
    def boot_to_pxe(enabled: "Once", mode: nil)
      @supermicro_client.boot_to_pxe(enabled: enabled, mode: mode)
    end
    
    def boot_to_disk(enabled: "Once", mode: nil)
      @supermicro_client.boot_to_disk(enabled: enabled, mode: mode)
    end
    
    def boot_to_cd(enabled: "Once", mode: nil)
      @supermicro_client.boot_to_cd(enabled: enabled, mode: mode)
    end
    
    def boot_to_usb(enabled: "Once", mode: nil)
      @supermicro_client.boot_to_usb(enabled: enabled, mode: mode)
    end
    
    def boot_to_bios_setup(enabled: "Once", mode: nil)
      @supermicro_client.boot_to_bios_setup(enabled: enabled, mode: mode)
    end
    
    def configure_boot_settings(persistence: nil, mode: nil)
      @supermicro_client.configure_boot_settings(persistence: persistence, mode: mode)
    end
    
    # PCI Devices
    
    def pci_devices
      # Supermicro has limited PCI device support
      # Try to get basic info from /redfish/v1/Chassis/1/PCIeDevices
      begin
        response = @supermicro_client.authenticated_request(:get, "/redfish/v1/Chassis/1/PCIeDevices")
        
        if response.status == 200
          data = JSON.parse(response.body)
          devices = []
          
          data["Members"].each do |member|
            device_path = member["@odata.id"]
            device_response = @supermicro_client.authenticated_request(:get, device_path)
            
            if device_response.status == 200
              device_data = JSON.parse(device_response.body)
              
              devices << OpenStruct.new(
                id: device_data["Id"],
                name: device_data["Name"],
                manufacturer: device_data["Manufacturer"],
                model: device_data["Model"],
                device_type: device_data["DeviceType"],
                device_class: device_data["Description"]&.include?("NIC") ? "NetworkController" : "Unknown",
                pcie_type: device_data.dig("PCIeInterface", "PCIeType"),
                lanes: device_data.dig("PCIeInterface", "LanesInUse")
              )
            end
          end
          
          return devices
        end
      rescue => e
        # Silently fail and return empty array
      end
      
      []
    end
    
    def nics_with_pci_info
      # Supermicro doesn't provide PCI slot mapping for NICs
      # Return NICs without PCI info
      nics = @supermicro_client.nics
      nics.map { |nic| OpenStruct.new(nic) }
    end
    
    # Jobs
    
    def jobs
      @supermicro_client.jobs
    end
    
    def job_status(job_id)
      @supermicro_client.job_status(job_id)
    end
    
    def wait_for_job(job_id, timeout: 600)
      @supermicro_client.wait_for_job(job_id, timeout: timeout)
    end
    
    def cancel_job(job_id)
      @supermicro_client.cancel_job(job_id)
    end
    
    def clear_jobs!
      @supermicro_client.clear_jobs!
    end
    
    def jobs_summary
      @supermicro_client.jobs_summary
    end
    
    # BMC Management
    
    def ensure_vendor_specific_bmc_ready!
      # For Supermicro, no specific action needed - BMC is always ready
      # This is a no-op but returns true for consistency
      true
    end
    
    # BIOS Configuration
    
    def bios_error_prompt_disabled?
      @supermicro_client.bios_error_prompt_disabled?
    end
    
    def bios_hdd_placeholder_enabled?
      @supermicro_client.bios_hdd_placeholder_enabled?
    end
    
    def bios_os_power_control_enabled?
      @supermicro_client.bios_os_power_control_enabled?
    end
    
    def ensure_sensible_bios!(options = {})
      @supermicro_client.ensure_sensible_bios!(options)
    end
    
    def ensure_uefi_boot
      @supermicro_client.ensure_uefi_boot
    end
    
    def set_one_time_boot_to_virtual_media
      # Use Supermicro's method for setting one-time boot to virtual media
      @supermicro_client.set_one_time_boot_to_virtual_media
    end
    
    def set_boot_order_hd_first
      # Use Supermicro's method for setting boot order to HD first
      @supermicro_client.set_boot_order_hd_first
    end
    
    # Utility
    
    def sel_log
      @supermicro_client.sel_log
    end
    
    def clear_sel_log
      @supermicro_client.clear_sel_log
    end
    
    def sel_summary(limit: 10)
      @supermicro_client.sel_summary(limit: limit)
    end
    
    def accounts
      @supermicro_client.accounts
    end
    
    def create_account(username:, password:, role: "Administrator")
      @supermicro_client.create_account(username: username, password: password, role: role)
    end
    
    def delete_account(username)
      @supermicro_client.delete_account(username)
    end
    
    def update_account_password(username:, new_password:)
      @supermicro_client.update_account_password(username: username, new_password: new_password)
    end
    
    def sessions
      @supermicro_client.sessions
    end
    
    def service_info
      @supermicro_client.service_info
    end
    
    def get_firmware_version
      @supermicro_client.get_firmware_version
    end
    
    def bmc_info
      # Combine various BMC-related information into a single response
      info = {}
      
      # Get firmware version
      info[:firmware_version] = @supermicro_client.get_firmware_version
      
      # Get Redfish version from service info
      service = @supermicro_client.service_info
      info[:redfish_version] = service["RedfishVersion"] if service.is_a?(Hash)
      
      # Get license info
      licenses = @supermicro_client.licenses
      if licenses.is_a?(Array) && !licenses.empty?
        # Look for the main BMC license
        main_license = licenses.find { |l| l["LicenseClass"] == "BMC" } || licenses.first
        info[:license_version] = main_license["LicenseVersion"] if main_license.is_a?(Hash)
      end
      
      # Get network info for MAC and IP
      network = @supermicro_client.get_bmc_network
      if network.is_a?(Hash)
        info[:mac_address] = network["mac"]
        info[:ip_address] = network["ipv4"]
        info[:hostname] = network["hostname"] || network["fqdn"]
      end
      
      # Get health status from system info if available
      system = @supermicro_client.system_info
      info[:health] = system["Status"]["Health"] if system.is_a?(Hash) && system.dig("Status", "Health")
      
      info
    end
    
    def system_health
      # Convert hash to OpenStruct for dot notation access
      health_data = @supermicro_client.system_health
      OpenStruct.new(health_data)
    end
    
    # License management
    
    def check_virtual_media_license
      @supermicro_client.check_virtual_media_license if @supermicro_client.respond_to?(:check_virtual_media_license)
    end
    
    def licenses
      @supermicro_client.licenses if @supermicro_client.respond_to?(:licenses)
    end
    
    def activate_license(license_key)
      @supermicro_client.activate_license(license_key) if @supermicro_client.respond_to?(:activate_license)
    end
    
    def clear_license(license_id)
      @supermicro_client.clear_license(license_id) if @supermicro_client.respond_to?(:clear_license)
    end
    
    # Additional Supermicro-specific methods
    
    def bios_attributes
      @supermicro_client.bios_attributes if @supermicro_client.respond_to?(:bios_attributes)
    end
    
    def set_bios_attribute(name, value)
      @supermicro_client.set_bios_attribute(name, value) if @supermicro_client.respond_to?(:set_bios_attribute)
    end
    
    def manager_network_protocol
      @supermicro_client.manager_network_protocol if @supermicro_client.respond_to?(:manager_network_protocol)
    end
    
    # Network management
    
    def get_bmc_network
      @supermicro_client.get_bmc_network
    end
    
    def set_bmc_network(ipv4: nil, mask: nil, gateway: nil, 
                        dns_primary: nil, dns_secondary: nil, hostname: nil, 
                        dhcp: false)
      @supermicro_client.set_bmc_network(
        ipv4: ipv4,
        mask: mask,
        gateway: gateway,
        dns_primary: dns_primary,
        dns_secondary: dns_secondary,
        hostname: hostname,
        dhcp: dhcp
      )
    end
    
    def set_bmc_dhcp
      @supermicro_client.set_bmc_dhcp
    end
  end
  
  # Register the adapter
  Radfish.register_adapter('supermicro', SupermicroAdapter)
  Radfish.register_adapter('smc', SupermicroAdapter)
end