# frozen_string_literal: true

# Entry point for `require "radfish-supermicro"`, which is what radfish's
# adapter auto-loading looks for and what the other adapter gems provide.
# Without it the adapter never registered from a plain `require "radfish"`.
require "radfish"
require_relative "radfish/supermicro/version"
require_relative "radfish/supermicro_adapter"

module Radfish
  module Supermicro
  end
end
