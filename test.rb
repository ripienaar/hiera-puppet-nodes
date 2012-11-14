require 'pp'
require 'lib/hiera/dsl.rb'

resources = Hiera::DSL::Resources.new
klasses = Hiera::DSL::Klasses.new

klasses.new_klass(:name => "klass", :resources => resources)

file = klasses.find("klass").add_resource(
  resources.new_resource(:type => :file,
                         :name => "/tmp/foo",
                         :properties => {:content => "hello world", :require => "Exec[/bin/echo start]"})
)

exec = klasses.find("klass").add_resource(
  resources.new_resource(:type => :exec,
                         :name => "/bin/date",
                         :properties => {:refreshonly => true})
)

klasses.find("klass").each_resource {|r| puts r}
