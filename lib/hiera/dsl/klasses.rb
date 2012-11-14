class Hiera
  class DSL
    # being lazy, not DRY at all, should unify the resources
    # and classes collections into a mixin or something
    class Klasses
      def initialize
        @klasses = []
      end

      def [](index)
        @klasses[index]
      end

      def index(klass)
        @klasses.index(klass)
      end

      def find_index(name)
        index(find(name))
      end

      def find(name)
        @klasses.select{|k| k.name == name}.first
      end

      def new_class(options)
        new = Klass.new(options)

        raise "Duplicate class %s" % new.name if find(new.name)

        @klasses << new

        new
      end
    end
  end
end
