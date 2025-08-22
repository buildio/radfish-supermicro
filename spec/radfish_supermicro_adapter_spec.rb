require 'spec_helper'

RSpec.describe Radfish::SupermicroAdapter do
  it "has a version number" do
    expect(Radfish::Supermicro::VERSION).not_to be nil
  end

  describe "adapter registration" do
    it "registers the supermicro adapter with Radfish" do
      expect(Radfish.get_adapter('supermicro')).to eq(Radfish::SupermicroAdapter)
    end

    it "registers the smc alias" do
      expect(Radfish.get_adapter('smc')).to eq(Radfish::SupermicroAdapter)
    end
  end

  describe "adapter instance" do
    let(:adapter) do
      described_class.new(
        host: '192.168.1.100',
        username: 'admin',
        password: 'password',
        verify_ssl: false
      )
    end

    it "creates an adapter instance" do
      expect(adapter).to be_a(Radfish::SupermicroAdapter)
    end

    it "has the correct vendor" do
      expect(adapter.vendor).to eq('supermicro')
    end

    it "responds to power management methods" do
      expect(adapter).to respond_to(:power_status)
      expect(adapter).to respond_to(:power_on)
      expect(adapter).to respond_to(:power_off)
    end

    it "responds to virtual media methods" do
      expect(adapter).to respond_to(:virtual_media)
      expect(adapter).to respond_to(:insert_virtual_media)
      expect(adapter).to respond_to(:eject_virtual_media)
    end

    it "responds to boot configuration methods" do
      expect(adapter).to respond_to(:boot_options)
      expect(adapter).to respond_to(:set_boot_override)
      expect(adapter).to respond_to(:boot_to_pxe)
    end
  end
end