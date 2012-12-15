class Hiera
  class DSL
    class Klass
      attr_reader :name, :resources, :resource_collection, :depends_on

      def initialize(options={})
        raise "Classes need a name" unless options[:name]
        raise "Classes need the resource collection" unless options[:resources]

        @name = options[:name]

        @resources = []
        @resource_collection = options[:resources]
        @depends_on = []

        # TODO: use anchors
        add_resource(@resource_collection.new_resource(:type => :notify, :name => "%s_start_anchor" % @name))

      end

      def add_dependency(dep)
        return if depends_on.include?(dep)
        depends_on << dep
      end

      def to_s
        "#<%s:%s>" % [self.class, @name]
      end

      def add_to_scope(scope)
        # TODO: use anchors
        add_resource(@resource_collection.new_resource(:type => :anchor, :name => "%s_end_anchor" % @name))

        compiler = scope.compiler
        main_stage = compiler.catalog.resource(:stage, :main)

        klass = Puppet::Parser::Resource.new("class", @name, :scope => compiler.newscope(nil))
        klass.scope.resource = klass

        compiler.add_class(@name)
        compiler.catalog.add_resource(klass)
        compiler.catalog.add_edge(main_stage, klass)

        each_resource do |resource|
          p_r = Puppet::Parser::Resource.new(resource.type, resource.name, :scope => klass.scope)

          resource.properties.each_pair do |k, v|
            p_r[k] = v
          end

          if resource.previous_resource
            previous_idx = @resources[resource.previous_resource]
            previous = @resource_collection[previous_idx]
            previous_resource = compiler.catalog.resource(previous.type, previous.name)

            p_r.set_parameter(:require, [p_r[:require]].flatten.compact <<  previous_resource)
          end

          compiler.add_resource(klass.scope, p_r)
        end

        # unless our previous class was also added inside us we add
        # a dependency between us and previous class
        @depends_on.each do |previous_class|
          if previous_class && !has_resource?(:class, previous_class)
            k = compiler.catalog.resource(:class, previous_class.to_sym)
            klass.set_parameter(:require, [klass[:require]].flatten.compact << k)
          end
        end
      end

      def each_resource
        @resources.each do |idx|
          yield(@resource_collection[idx])
        end
      end

      def previous_resource(resource_id)
        idx = @resources.index(resource_id)

        return nil if idx == 0

        idx - 1
      end

      def add_resource(resource)
        idx = @resource_collection.index(resource)
        resource = @resource_collection[idx]

        raise "Resource already belong to a class" if resource.parent_class

        @resources << idx

        resource.parent_class = self
        resource.previous_resource = previous_resource(idx)

        @resource_collection[resource.previous_resource].next_resource = idx if resource.previous_resource

        resource
      end

      def has_resource?(type, title)
        @resources.select {|idx|
          r = @resource_collection[idx]
          r.type.to_s == type.to_s && r.name.to_s == name.to_s
        }.to_a.size == 1
      end
    end
  end
end
