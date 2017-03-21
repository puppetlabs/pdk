# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'pdk/version'

Gem::Specification.new do |spec|
  spec.name    = 'pdk'
  spec.version = PDK::VERSION
  spec.authors = ['David Schmitt']
  spec.email   = ['david.schmitt@puppet.com']

  spec.summary     = %q{The shortest path to better modules: Puppet Development Kit}
  spec.description = %q{A CLI tool to facilitate easy, unified development workflows for puppet modules.}
  spec.homepage    = 'https://github.com/puppetlabs/pdk'

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_runtime_dependency 'cri', '~> 2.7.1'
  spec.add_runtime_dependency 'childprocess', '~> 0.6.2'
end
