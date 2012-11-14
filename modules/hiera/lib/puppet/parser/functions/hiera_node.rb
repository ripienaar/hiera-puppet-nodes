module Puppet::Parser::Functions
  newfunction(:hiera_node) do |*args|
    require "lib/hiera/dsl.rb"
    require "pp"

    h_r = Hiera::DSL::Resources.new
    h_k = Hiera::DSL::Klasses.new

    classes = function_hiera_array(["classes"])

    # create the various H::D::Klass resources
    Hiera::DSL.create_classes(classes, h_r, h_k)

    # walk the classes list finding any ordering hints and add
    # them to our internal structures
    Hiera::DSL.add_relationships_to_classes(classes, h_k)

    # read the class yaml file containing resources, add all the resources
    # to internal structures in the right H::D::Klass and finally add the
    # H::D::Klass to puppet
    classes.map{|a| a.split(/\s*->\s*/)}.flatten.uniq.each do |klass_name|
      Hiera::DSL.add_resources_from_file(klass_name, self, h_r, h_k)
    end

    # with all our classes in puppet we can now add the ordering we
    # need into the puppet catalog
    Hiera::DSL.add_class_relationships_to_puppet(classes, compiler.catalog, h_k)
  end
end
