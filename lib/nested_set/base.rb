# encoding: utf-8
module NestedSet
  module Base
    def self.included(base)
      base.extend(SingletonMethods)
    end

    module SingletonMethods
      # Configuration options are:
      #
      # * +:parent_column+ - specifies the column name to use for keeping the position integer (default: parent_id)
      # * +:left_column+ - column name for left boundry data, default "lft"
      # * +:right_column+ - column name for right boundry data, default "rgt"
      # * +:depth_column+ - column name for level cache data, default "depth"
      # * +:scope+ - restricts what is to be considered a list. Given a symbol, it'll attach "_id"
      #   (if it hasn't been already) and use that as the foreign key restriction. You
      #   can also pass an array to scope by multiple attributes.
      #   Example: <tt>acts_as_nested_set :scope => [:notable_id, :notable_type]</tt>
      def acts_as_nested_set(options = {})
        options = {
          :primary_key => self.primary_key,
          :left_column => "lft",
          :right_column => "rgt",
          :parent_column => "parent_id",
          :depth_column => "depth",
          :scope => nil
        }.merge(options)

        if options[:scope].is_a?(Symbol) && options[:scope].to_s !~ /_id\z/
          options[:scope] = "#{options[:scope].to_s}_id".to_sym
        end

        class_attribute :acts_as_nested_set_options
        self.acts_as_nested_set_options = options

        unless self.is_a?(ClassMethods)
          include InstanceMethods
          include Columns
          extend Columns
          extend ClassMethods

          belongs_to :parent, :class_name => self.base_class.to_s,
            :foreign_key => parent_column_name
          has_many :children, :class_name => self.base_class.to_s,
            :foreign_key => parent_column_name, :order => quoted_left_column_name

          # no bulk assignment
          if accessible_attributes.blank?
            attr_protected  left_column_name.intern, right_column_name.intern
          end

          # no assignment to structure fields
          [left_column_name, right_column_name].each do |column|
            module_eval <<-"end_eval", __FILE__, __LINE__
            def #{column}=(x)
              raise ActiveRecord::ActiveRecordError, "Unauthorized assignment to #{column}: it's an internal field handled by acts_as_nested_set code, use move_to_* methods instead."
            end
            end_eval
          end

          scope :roots, lambda {
            where(parent_column_name => nil).order(quoted_left_column_name)
          }
          scope :leaves, lambda {
            where("#{quoted_right_column_name} - #{quoted_left_column_name} = 1").
            order(quoted_left_column_name)
          }
        end
      end
    end

    module ClassMethods
      # returns the first root element
      def root
        roots.first
      end

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

      def primary_key_column_name
        acts_as_nested_set_options[:primary_key]
      end

      def scope_column_names
        Array(acts_as_nested_set_options[:scope])
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

      def quoted_parent_column_name
        connection.quote_column_name(parent_column_name)
      end

      def quoted_depth_column_name
        connection.quote_column_name(depth_column_name)
      end

      def quoted_primary_key_column_name
        connection.quote_column_name(primary_key_column_name)
      end
    end

    module InstanceMethods
      # Value of the parent column
      def parent_id
        self[parent_column_name]
      end

      # Value of the left column
      def left
        self[left_column_name]
      end

      # Value of the right column
      def right
        self[right_column_name]
      end

      def root?
        parent_id.nil?
      end

      # Returns root
      def root
        self_and_ancestors.first
      end

      def leaf?
        !new_record? && (right - left) == 1
      end

      # Returns the array of self and all children
      def self_and_children
        nested_set_scope.where("#{q_parent} = :id or #{q_primary_key} = :id", :id => self)
      end

      # Returns the array of all parents and self
      def self_and_ancestors
        nested_set_scope.where("#{q_left} <= ? AND #{q_right} >= ?", left, right)
      end

      # Returns an array of all parents
      def ancestors
        without_self self_and_ancestors
      end

      # Returns the array of all children of the parent, including self
      def self_and_siblings
        nested_set_scope.where(parent_column_name => parent_id)
      end

      # Returns a set of itself and all of its nested children
      def self_and_descendants
        nested_set_scope.where("#{q_left} >= ? AND #{q_right} <= ?", left, right)
      end

      # Returns a set of all of its children and nested children
      def descendants
        without_self self_and_descendants
      end

      # Returns true is this is a child node
      def child?
        !parent_id.nil?
      end

      protected
        def q_left
          "#{self.class.quoted_table_name}.#{quoted_left_column_name}"
        end

        def q_right
          "#{self.class.quoted_table_name}.#{quoted_right_column_name}"
        end

        def q_parent
          "#{self.class.quoted_table_name}.#{quoted_parent_column_name}"
        end

        def q_primary_key
          "#{self.class.quoted_table_name}.#{quoted_primary_key_column_name}"
        end

        def without_self(scope)
          scope.where("#{q_primary_key} != ?", self)
        end

        # All nested set queries should use this nested_set_scope, which performs finds on
        # the base ActiveRecord class, using the :scope declared in the acts_as_nested_set
        # declaration.
        #
        # :scope => [:notable_id, :notable_type]
        # conditions = {:notable_id=>"self[notable_id]", :notable_type=>"self[notable_type]"}
        def nested_set_scope
          conditions = scope_column_names.inject({}) do |cnd, attr|
            cnd.merge attr => self[attr]
          end
          self.class.base_class.order(q_left).where(conditions)
        end
    end
  end
end
