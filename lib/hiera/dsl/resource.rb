class Hiera
  class DSL
    class Resource
      attr_reader :type, :name, :properties
      attr_accessor :parent_class, :next_resource, :previous_resource

      def initialize(options={})
        raise "Resources need a type" unless options[:type]
        raise "Resources need a name" unless options[:name]

        @type = options[:type]
        @name = options[:name]
        @properties = options.fetch(:properties, {})

        @parent_class = nil
        @next_resource = nil
        @previous_resource = nil
      end

      def to_s
        if @parent_class
          "<resource#%d %s[%s]>" % [@parent_class.resource_collection.index(self), @type.to_s.capitalize, @name]
        else
          "<%s[%s]>" % [@type.to_s.capitalize, @name]
        end
      end

      def merge!(properties)
        @properties.merge!(properties)
      end

      def []=(key, val)
        @properties[key] = val
      end

      def [](key)
        @properties[key]
      end
    end
  end
end
