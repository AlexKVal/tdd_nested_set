# encoding: utf-8
module NestedSet
  module Base
    def self.included(base)
      base.extend(SingletonMethods)
    end
    
    module SingletonMethods
      def acts_as_nested_set(options = {})
        #
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