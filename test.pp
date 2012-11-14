class static {
    notify{"static": }
}

node "default" {

    create_resources("class", {"static" => {}})

    notice(inline_template('<%=
       compiler = scope.compiler
       main_stage = compiler.catalog.resource(:stage, :main)

       klass = Puppet::Parser::Resource.new("class", "dynamic", :scope => compiler.newscope(nil))
       klass.scope.resource = klass

       compiler.add_class("dynamic")
       compiler.catalog.add_edge(main_stage, klass)

       date = Puppet::Parser::Resource.new(:exec, "/bin/date", :scope => klass.scope)
       date[:refreshonly] = true
       compiler.add_resource(klass.scope, date)

       require "pp"
       compiler.catalog.pretty_inspect
    %>'))

    notify{"X": notify => Class["dynamic"]}
}
