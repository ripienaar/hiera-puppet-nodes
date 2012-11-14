require 'yaml'

puts ({
  "resources" => [
    {"exec" => [{"one" => nil},
                {"two" => {"refreshonly" => true}}
               ]
    },
    {"file" => [{"/tmp/foo" => {"content" => "hello"}}]}
  ]
}).to_yaml
