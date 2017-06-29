require 'open3'

shared_context 'in a new module' do |name|
  before(:all) do
    output, status = Open3.capture2e('pdk', 'new', 'module', name, '--skip-interview', '--template-url', "file://#{RSpec.configuration.template_dir}")

    raise "Failed to create test module:\n#{output}" unless status.success?

    Dir.chdir(name)
  end

  after(:all) do
    Dir.chdir('..')
    FileUtils.rm_rf(name)
  end
end
