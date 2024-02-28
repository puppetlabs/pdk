lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'pdk/version'

Gem::Specification.new do |spec|
  spec.name    = 'pdk'
  spec.version = PDK::VERSION
  spec.authors = ['Puppet, Inc.']
  spec.email   = ['pdk-maintainers@puppet.com']

  spec.summary     = 'A key part of the Puppet Development Kit, the shortest path to better modules'
  spec.description = 'A CLI to facilitate easy, unified development workflows for Puppet modules.'
  spec.homepage    = 'https://github.com/puppetlabs/pdk'

  spec.files         = Dir['CHANGELOG.md', 'README.md', 'LICENSE', 'lib/**/*', 'exe/**/*']
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.required_ruby_version = '>= 2.7.0'

  spec.add_runtime_dependency 'CFPropertyList', '>= 2.2', '< 3.0.7'

  spec.add_runtime_dependency 'bundler', '>= 2.1.0', '< 3.0.0'
  spec.add_runtime_dependency 'childprocess', '~> 4.1.0'
  spec.add_runtime_dependency 'cri', '~> 2.15.11'
  spec.add_runtime_dependency 'diff-lcs', '>= 1.5.0'
  spec.add_runtime_dependency 'ffi', '>= 1.15.5', '< 2.0.0'
  spec.add_runtime_dependency 'hitimes', '2.0.0'
  spec.add_runtime_dependency 'json_pure', '~> 2.6.3'
  spec.add_runtime_dependency 'json-schema', '~> 4.0'
  spec.add_runtime_dependency 'minitar', '~> 0.8'
  spec.add_runtime_dependency 'pathspec', '~> 1.1'
  spec.add_runtime_dependency 'tty-prompt', '~> 0.23'
  spec.add_runtime_dependency 'tty-spinner', '~> 0.9'
  spec.add_runtime_dependency 'tty-which', '~> 0.5'

  # Analytics dependencies
  spec.add_runtime_dependency 'concurrent-ruby', '~> 1.0'
  spec.add_runtime_dependency 'facter', '~> 4.0'
  spec.add_runtime_dependency 'httpclient', '~> 2.8.3'

  # Used in the pdk-templates
  spec.add_runtime_dependency 'deep_merge', '~> 1.2.2'
  spec.metadata['rubygems_mfa_required'] = 'true'
end
