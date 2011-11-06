# encoding: utf-8
require 'nested_set'
require 'rails/railtie'

module NestedSet
  class Railtie < ::Rails::Railtie
    def self.extend_active_record
      ActiveRecord::Base.send :include, NestedSet::Base
    end
  end
end