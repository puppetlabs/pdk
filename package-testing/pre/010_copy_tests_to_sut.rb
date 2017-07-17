test_name 'Copy pdk acceptance to the System Under Test and bundle install' do
  require 'pdk/pdk_helper.rb'

  # TODO: Need assurance that the ref of the acceptance tests is
  # correct for the ref of the package being tested.

  step 'Create target directory' do
    on(workstation, "mkdir -p #{target_dir}")
  end

  # Required directories from pdk repo to run tests
  %w[spec lib locales exe].each do |dir|
    step "Copy #{dir} dir from pdk repo to System Under Test" do
      scp_to(workstation, dir, "#{target_dir}/#{dir}")
    end
  end

  # Required files from pdk repo to run tests
  %w[Gemfile pdk.gemspec].each do |file|
    step "Copy #{file} from pdk repo to System Under Test" do
      scp_to(workstation, file, target_dir)
    end
  end

  # This is required on Windows - git otherwise only allows 260 chars in a path.
  step 'Allow long paths in git before running bundle install' do
    on(workstation, "#{command_prefix(workstation)} git config --global core.longpaths true")
  end

  step 'Install pdk gem bundle using pdk\'s ruby' do
    on(workstation, "#{command_prefix(workstation)} bundle install --path vendor/bundle --without development package_testing --jobs 4 --retry 4")
  end

  step 'Check rspec is ready' do
    on(workstation, "#{command_prefix(workstation)} bundle exec rspec --version") do |outcome|
      assert_match(%r{[0-9\.]*}, outcome.stdout, 'rspec --version outputs some version number')
    end
  end
end
