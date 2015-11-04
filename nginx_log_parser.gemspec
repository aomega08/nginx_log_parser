$LOAD_PATH.unshift File.expand_path("../lib", __FILE__)
require "nginx_log_parser/version"

Gem::Specification.new do |s|
  s.name        = 'nginx_log_parser'
  s.version     = NginxLogParser::VERSION
  s.summary     = "Hola!"
  s.description = "A simple hello world gem"
  s.authors     = ["Francesco Boffa"]
  s.email       = 'fra.boffa@gmail.com'
  s.files       = `git ls-files -- lib/*`.split("\n") 
  s.homepage    = 'https://github.com/aomega08/nginx_log_parser'
  s.license     = 'MIT'
end

