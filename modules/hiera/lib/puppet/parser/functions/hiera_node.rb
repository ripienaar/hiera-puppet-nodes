module Puppet::Parser::Functions
  newfunction(:hiera_node) do |*args|
    require "lib/hiera/dsl.rb"
    require "pp"


    klasses = function_hiera_array(["classes"])

    h_r = Hiera::DSL::Resources.new

    klasses.each do |klass_name|
      klass = Hiera::DSL::Klass.new(:name => klass_name, :resources => h_r)

      module_file = File.join(Hiera::Config[:yaml][:datadir], "classes", "#{klass_name}.yaml")

      raise "Cannot find class %s" % klass_name unless File.exist?(module_file)

      klass_resources = YAML.load_file(module_file)

      raise "Could not find any resources in %s" % module_file unless klass_resources["resources"]

      klass_resources["resources"].each do |resources|
        resources.keys.each do |type|
          resources[type].each do |resource_of_type|
            if resource_of_type.is_a?(String)
              override_name = "%s::%s" % [type, resource_of_type]
              overrides = function_hiera_hash([override_name, {}])

              klass.add_resource(r = h_r.new_resource(:type => type, :name => resource_of_type))
              r.merge!(overrides)

            elsif resource_of_type.is_a?(Hash)
              resource_of_type.keys.each do |name|
                override_name = "%s::%s" % [type, name]
                overrides = function_hiera_hash([override_name, {}])

                klass.add_resource(r = h_r.new_resource(:type => type, :name => name, :properties => resource_of_type[name]))
                r.merge!(overrides)
              end
            end
          end
        end
      end

      klass.add_to_scope(self)
    end
  end
end
