class Hiera
  class DSL
    class Resources
      def initialize
        @resources = []
      end

      def [](index)
        @resources[index]
      end

      def index(resource)
        @resources.index(resource)
      end

      def find_index(type, name)
        index(find(type, name))
      end

      def find(type, name)
        @resources.select{|r| r.name == name && r.type == type }.first
      end

      def new_resource(options)
        new = Resource.new(options)

        raise "Duplicate resource %s[%s]" % [new.type, new.name] if find(new.type, new.name)

        @resources << new

        new
      end
    end
  end
end
