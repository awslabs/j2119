Gem::Specification.new do |s|
  s.name        = 'j2119'
  s.version     = '0.0.2'
  s.date        = '2016-09-28'
  s.summary     = "JSON DSL Validator"
  s.description = "Validates JSON objects based on constraints in RFC2119-like language"
  s.authors     = ["Tim Bray"]
  s.email       = 'timbray@amazon.com'
  s.files       = [
    "lib/j2119.rb",
    "lib/j2119/assigner.rb", 
    "lib/j2119/conditional.rb",
    "lib/j2119/constraints.rb",
    "lib/j2119/deduce.rb",
    "lib/j2119/matcher.rb",
    "lib/j2119/node_validator.rb",
    "lib/j2119/oxford.rb",
    "lib/j2119/parser.rb",
    "lib/j2119/role_constraints.rb",
    "lib/j2119/role_finder.rb",
    "lib/j2119/allowed_fields.rb",
    "lib/j2119/json_path_checker.rb"
  ]
  s.homepage    =
    'http://rubygems.org/gems/j2119'
  s.license       = 'Apache 2.0'
end
