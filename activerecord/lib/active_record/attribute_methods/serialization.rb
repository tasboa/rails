module ActiveRecord
  module AttributeMethods
    module Serialization
      extend ActiveSupport::Concern

      module ClassMethods
        # If you have an attribute that needs to be saved to the database as an
        # object, and retrieved as the same object, then specify the name of that
        # attribute using this method and it will be handled automatically. The
        # serialization is done through YAML. If +class_name+ is specified, the
        # serialized object must be of that class on retrieval or
        # <tt>SerializationTypeMismatch</tt> will be raised.
        #
        # A notable side effect of serialized attributes is that the model will
        # be updated on every save, even if it is not dirty.
        #
        # ==== Parameters
        #
        # * +attr_name+ - The field name that should be serialized.
        # * +class_name_or_coder+ - Optional, a coder object, which responds to `.load` / `.dump`
        #   or a class name that the object type should be equal to.
        #
        # ==== Example
        #
        #   # Serialize a preferences attribute.
        #   class User < ActiveRecord::Base
        #     serialize :preferences
        #   end
        #
        #   # Serialize preferences using JSON as coder.
        #   class User < ActiveRecord::Base
        #     serialize :preferences, JSON
        #   end
        #
        #   # Serialize preferences as Hash using YAML coder.
        #   class User < ActiveRecord::Base
        #     serialize :preferences, Hash
        #   end
        def serialize(attr_name, class_name_or_coder = Object)
          coder = if [:load, :dump].all? { |x| class_name_or_coder.respond_to?(x) }
                    class_name_or_coder
                  else
                    Coders::YAMLColumn.new(class_name_or_coder)
                  end

          decorate_attribute_type(attr_name, :serialize) do |type|
            Type::Serialized.new(type, coder)
          end
        end

        def serialized_attributes
          ActiveSupport::Deprecation.warn(<<-WARNING.strip_heredoc)
            `serialized_attributes` is deprecated, and will be removed in Rails 5.0.
            If you need to access the serialization behavior, you can do:

              #{self.class.name}.column_for_attribute('foo').type_cast_for_database(value)

            or

              #{self.class.name}.column_for_attribute('foo').type_cast_from_database(value)
          WARNING
          @serialized_attributes ||= Hash[
            columns.select { |t| t.cast_type.is_a?(Type::Serialized) }.map { |c|
              [c.name, c.cast_type.coder]
            }
          ]
        end
      end
    end
  end
end
