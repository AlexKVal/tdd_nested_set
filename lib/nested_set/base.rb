# encoding: utf-8
module NestedSet
  module Base
    def self.included(base)
      base.extend(SingletonMethods)
    end
    
    module SingletonMethods
      # Configuration options are:
      #
      # * +:left_column+ - column name for left boundry data, default "lft"
      # * +:right_column+ - column name for right boundry data, default "rgt"
      def acts_as_nested_set(options = {})
        options = {
          :left_column => "lft",
          :right_column => "rgt",
          :parent_column => "parent_id",
          :depth_column => "depth"
        }.merge(options)
        
        class_attribute :acts_as_nested_set_options
        self.acts_as_nested_set_options = options
      end
    end
    
    module ClassMethods
      #
    end
    
    #module Columns      
    #end
    
    module InstanceMethods
      #
    end
  end
end