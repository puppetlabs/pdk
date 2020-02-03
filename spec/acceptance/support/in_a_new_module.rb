require 'open3'

shared_context 'in a new module' do |name, options = {}|
  before(:all) do
    default_template = RSpec.configuration.template_dir
    default_template = 'file:///' + default_template unless Gem.win_platform?
    template = options.fetch(:template, default_template)
    argv = [
      'pdk', 'new', 'module', name,
      '--skip-interview',
      '--template-url', template
    ]
    env = { 'PDK_ANSWER_FILE' => File.join(Dir.pwd, "#{name}_answers.json") }
    output, status = Open3.capture2e(env, *argv)

    raise "Failed to create test module:\n#{output}" unless status.success?

    Dir.chdir(name)
  end

  after(:all) do
    Dir.chdir('..')
    FileUtils.rm_rf(name)
    FileUtils.rm_f("#{name}_answers.json")
  end
end
