Gem::Specification.new do |s|
  s.name = "helloredis"
  s.summary = "A Ruby interface to the Hiredis Redis client library"
  s.version = "0.0.1"
  s.author = "Paul Mucur"
  s.email = "helloredis@librelist.com"
  s.files = Dir["lib/*.rb"] + Dir["spec/*.rb"] + ["README.md"]
  s.homepage = "http://mudge.github.com/helloredis"
  s.test_files = Dir["spec/*.rb"]
  s.add_dependency("ffi")
  s.add_development_dependency("rspec")
end
