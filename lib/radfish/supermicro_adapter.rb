# frozen_string_literal: true

require 'supermicro'

module Radfish
  class SupermicroAdapter < Core::BaseClient
    include Core::Power
    include Core::System
    include Core::Storage
    include Core::VirtualMedia
    include Core::Boot
    include Core::Jobs
    include Core::Utility
    
    attr_reader :supermicro_client
    
    def initialize(host:, username:, password:, **options)
      super
      
      # Create the underlying Supermicro client
      @supermicro_client = Supermicro::Client.new(
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
    
    def power_on
      @supermicro_client.power_on
    end
    
    def power_off(force: false)
      @supermicro_client.power_off(force: force)
    end
    
    def power_restart(force: false)
      @supermicro_client.power_restart(force: force)
    end
    
    def power_cycle
      @supermicro_client.power_cycle
    end
    
    def reset_type_allowed
      @supermicro_client.reset_type_allowed
    end
    
    # System information
    
    def system_info
      @supermicro_client.system_info
    end
    
    def cpus
      @supermicro_client.cpus
    end
    
    def memory
      @supermicro_client.memory
    end
    
    def nics
      @supermicro_client.nics
    end
    
    def fans
      @supermicro_client.fans
    end
    
    def temperatures
      @supermicro_client.temperatures
    end
    
    def psus
      @supermicro_client.psus
    end
    
    def power_consumption
      @supermicro_client.power_consumption
    end
    
    # Storage
    
    def storage_controllers
      @supermicro_client.storage_controllers
    end
    
    def drives
      @supermicro_client.drives
    end
    
    def volumes
      @supermicro_client.volumes
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
    end
    
    def eject_virtual_media(device: nil)
      @supermicro_client.eject_virtual_media(device: device)
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
    
    def boot_options
      @supermicro_client.boot_options
    end
    
    def set_boot_override(target, persistence: nil, mode: nil, persistent: false)
      # Pass all parameters through to the supermicro client
      @supermicro_client.set_boot_override(target, 
                                          persistence: persistence,
                                          mode: mode,
                                          persistent: persistent)
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
    
    def boot_to_pxe(persistence: nil, mode: nil)
      @supermicro_client.boot_to_pxe(persistence: persistence, mode: mode)
    end
    
    def boot_to_disk(persistence: nil, mode: nil)
      @supermicro_client.boot_to_disk(persistence: persistence, mode: mode)
    end
    
    def boot_to_cd(persistence: nil, mode: nil)
      @supermicro_client.boot_to_cd(persistence: persistence, mode: mode)
    end
    
    def boot_to_usb(persistence: nil, mode: nil)
      @supermicro_client.boot_to_usb(persistence: persistence, mode: mode)
    end
    
    def boot_to_bios_setup(persistence: nil, mode: nil)
      @supermicro_client.boot_to_bios_setup(persistence: persistence, mode: mode)
    end
    
    def configure_boot_settings(persistence: nil, mode: nil)
      @supermicro_client.configure_boot_settings(persistence: persistence, mode: mode)
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
    
    def clear_completed_jobs
      @supermicro_client.clear_completed_jobs
    end
    
    def jobs_summary
      @supermicro_client.jobs_summary
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
  end
  
  # Register the adapter
  Radfish.register_adapter('supermicro', SupermicroAdapter)
  Radfish.register_adapter('smc', SupermicroAdapter)
end