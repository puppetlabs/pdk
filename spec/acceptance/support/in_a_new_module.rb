require 'open3'

shared_context 'in a new module' do |name, options = {}|
  before(:all) do
    template = options.fetch(:template, "file:///#{RSpec.configuration.template_dir}")
    argv = [
      'pdk', 'new', 'module', name,
      '--skip-interview',
      '--template-url', template,
      '--answer-file', File.join(Dir.pwd, "#{name}_answers.json")
    ]
    output, status = Open3.capture2e(*argv)

    raise "Failed to create test module:\n#{output}" unless status.success?

    Dir.chdir(name)
  end

  after(:all) do
    Dir.chdir('..')
    FileUtils.rm_rf(name)
    FileUtils.rm("#{name}_answers.json")
  end
end
