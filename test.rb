require 'pp'
require 'lib/hiera/dsl/resources.rb'
require 'lib/hiera/dsl/resource.rb'
require 'lib/hiera/dsl/klass.rb'

resources = Hiera::DSL::Resources.new

klass = Hiera::DSL::Klass.new(:name => "klass", :resources => resources)

klass.add_resource(file = resources.new_resource(:type => :file, :name => "/tmp/foo"))
klass.add_resource(exec = resources.new_resource(:type => :exec, :name => "/bin/date"))

file.merge!(:content => "hello world", :require => "Exec[/bin/echo start]")
exec.merge!(:refreshonly => true)

klass.each_resource {|r| puts r}
