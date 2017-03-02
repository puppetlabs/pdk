# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'pick/version'

Gem::Specification.new do |spec|
  spec.name    = 'pick'
  spec.version = Pick::VERSION
  spec.authors = ['David Schmitt']
  spec.email   = ['david.schmitt@puppet.com']

  spec.summary     = %q{The shortest path to better modules: Puppet Infrastructure Construction Kit}
  spec.description = %q{A CLI tool to facilitate easy, unified development workflows for puppet modules.}
  spec.homepage    = 'https://github.com/puppetlabs/pick'

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_runtime_dependency 'thor', '~> 0.19.0'
end
