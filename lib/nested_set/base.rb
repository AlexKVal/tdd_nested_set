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
          :depth_column => "depth",
          :scope => nil
        }.merge(options)

        class_attribute :acts_as_nested_set_options
        self.acts_as_nested_set_options = options

        unless self.is_a?(ClassMethods)
          include Columns
          extend Columns
          extend ClassMethods
        end
      end
    end

    module ClassMethods
      #
    end

    # Mixed into both classes and instances to provide easy access to the column names
    module Columns
      def left_column_name
        acts_as_nested_set_options[:left_column]
      end
      
      def right_column_name
        acts_as_nested_set_options[:right_column]
      end
      
      def parent_column_name
        acts_as_nested_set_options[:parent_column]
      end
      
      def depth_column_name
        acts_as_nested_set_options[:depth_column]
      end
      
      def quoted_left_column_name
        connection.quote_column_name(left_column_name)
      end
      
      def quoted_right_column_name
        connection.quote_column_name(right_column_name)
      end
      
      def quoted_depth_column_name
        connection.quote_column_name(depth_column_name)
      end
    end

    module InstanceMethods
      #
    end
  end
end
