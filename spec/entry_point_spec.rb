require 'spec_helper'

# radfish auto-loads adapters with `require "radfish-<vendor>"` inside a
# `rescue LoadError`, so a missing entry point fails silently: the adapter
# never registers and nothing complains.
RSpec.describe 'require "radfish-supermicro"' do
  it 'is loadable by the gem name' do
    expect { require 'radfish-supermicro' }.not_to raise_error
  end

  it 'registers the adapter under both names radfish knows' do
    require 'radfish-supermicro'

    expect(Radfish.get_adapter('supermicro')).to eq(Radfish::SupermicroAdapter)
    expect(Radfish.get_adapter('smc')).to eq(Radfish::SupermicroAdapter)
    expect(Radfish.supported_vendors).to include('supermicro')
  end
end
