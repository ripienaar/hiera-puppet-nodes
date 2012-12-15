class Hiera
  class DSL
    require 'hiera/dsl/resource'
    require 'hiera/dsl/resources'
    require 'hiera/dsl/klasses'
    require 'hiera/dsl/klass'

    # create classes in our own data structures without any
    # ordering etc, just the classes
    def self.create_classes(list, resources, classes)
      list.map{|a| a.split(/\s*->\s*/)}.flatten.uniq.each do |klass_name|
        next if classes.find(klass_name)

        classes.new_class(:name => klass_name, :resources => resources)
      end
    end

    def self.parse_string_for_hiera_var(string, scope)
      data = string.clone

      if data.is_a?(String)
        while data =~ /\$\{(.+?)\}/
          hieravar = $1
          value = scope.function_hiera([hieravar])

          raise("Could not find a value for %s in %s" % [hieravar, data]) unless value

          data.gsub!(/\$\{.+?\}/, value)
        end
      elsif data.is_a?(Hash)
        data.keys.each do |key|
          data[key] = parse_string_for_hiera_var(data[key], scope)
        end
      end

      data
    end

    # add resources in a file to the classes in our internal structures
    # and then add each class with its resources to puppet
    def self.add_resources_from_file(class_name, scope, h_r, h_k)
      module_file = File.join(Hiera::Config[:yaml][:datadir], "classes", "#{class_name}.yaml")

      raise "Cannot find class %s" % class_name unless File.exist?(module_file)

      klass_resources = YAML.load_file(module_file)

      raise "Could not find any resources in %s" % module_file unless klass_resources["resources"]

      klass_resources["resources"].each do |resources|
        resources.keys.each do |type|
          resources[type].each do |resource_of_type|
            if resource_of_type.is_a?(String)
              resource_of_type = {parse_string_for_hiera_var(resource_of_type, scope) => {}}
            end

            resource_of_type.keys.each do |name|
              override_name = "%s::%s" % [type, name]
              overrides = parse_string_for_hiera_var(scope.function_hiera_hash([override_name, {}]), scope)

              h_k.find(class_name).add_resource(r = h_r.new_resource(:type => type, :name => name, :properties => parse_string_for_hiera_var(resource_of_type[name], scope)))
              r.merge!(overrides)
            end
          end
        end
      end

      h_k.find(class_name).add_to_scope(scope)
    end

    # add the previous classes as defined in the yaml to our
    # own classes
    def self.add_relationships_to_classes(classes, h_k)
      classes.map{|a| a.split(/\s*->\s*/)}.each do |klass|
        if klass.is_a?(Array)
          previous = nil

          klass.each do |k|
            if previous
              h_k.find(k).add_dependency(previous)
            end

            previous = k
          end
        end
      end
    end

    # add the relationships from our own classes into the puppet catalog
    def self.add_class_relationships_to_puppet(classes, catalog, h_k)
      h_k.each do |k|
        target = catalog.resource(:class, k.name)
        k.depends_on.each do |dep|
          dependency = catalog.resource(:class, dep)

          target.set_parameter(:require, [target[:require]].flatten.compact << dependency)
        end
      end
    end
  end
end
