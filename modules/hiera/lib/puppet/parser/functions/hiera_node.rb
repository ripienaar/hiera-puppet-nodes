module Puppet::Parser::Functions
  newfunction(:hiera_node) do |*args|
    require "lib/hiera/dsl.rb"
    require "pp"

    klasses = function_hiera_array(["classes"])

    h_r = Hiera::DSL::Resources.new
    h_k = Hiera::DSL::Klasses.new

    # add all the classes ignoring ordering and relationships
    klasses.map{|a| a.split(/\s*->\s*/)}.flatten.each do |klass_name|
      h_k.new_class(:name => klass_name, :resources => h_r)

      module_file = File.join(Hiera::Config[:yaml][:datadir], "classes", "#{klass_name}.yaml")

      raise "Cannot find class %s" % klass_name unless File.exist?(module_file)

      klass_resources = YAML.load_file(module_file)

      raise "Could not find any resources in %s" % module_file unless klass_resources["resources"]

      klass_resources["resources"].each do |resources|
        resources.keys.each do |type|
          resources[type].each do |resource_of_type|
            if resource_of_type.is_a?(String)
              resource_of_type = {resource_of_type => {}}
            end

            resource_of_type.keys.each do |name|
              override_name = "%s::%s" % [type, name]
              overrides = function_hiera_hash([override_name, {}])

              h_k.find(klass_name).add_resource(r = h_r.new_resource(:type => type, :name => name, :properties => resource_of_type[name]))
              r.merge!(overrides)
            end
          end
        end
      end

      h_k.find(klass_name).add_to_scope(self)
    end

    # now add relationships where specified
    klasses.map{|a| a.split(/\s*->\s*/)}.each do |klass|
      if klass.is_a?(Array)
        previous = nil

        klass.each do |k|
          if previous
            pk = compiler.catalog.resource(:class, previous.to_sym)
            ck = compiler.catalog.resource(:class, k)

            ck.set_parameter(:require, [ck[:require]].flatten.compact << pk)

            previous = k
          else
            previous = k
          end
        end
      end
    end
  end
end
