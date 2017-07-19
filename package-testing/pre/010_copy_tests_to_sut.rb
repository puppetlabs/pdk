test_name 'Copy pdk acceptance to the System Under Test and bundle install' do
  require 'pdk/pdk_helper.rb'

  # TODO: Need assurance that the ref of the acceptance tests is
  # correct for the ref of the package being tested.

  step 'Create target directory' do
    on(workstation, "mkdir -p #{target_dir}")
  end

  step 'Copy spec/ dir from pdk repo to System Under Test' do
    scp_to(workstation, 'spec', "#{target_dir}/spec")
  end

  # Windows requires a specific Nokogiri before installing rspec-xsd
  if workstation.platform =~ %r{windows}
    step 'Install specific Nokogiri for Windows' do
      on(workstation, "#{command_prefix(workstation)} gem install nokogiri -v 1.6.8")
    end
  end

  # Required gem installs for spec tests to execute
  %w[rspec rspec-xsd serverspec].each do |gem|
    step "gem install #{gem} (required to run tests)" do
      on(workstation, "#{command_prefix(workstation)} gem install #{gem}")
    end
  end

  if workstation.platform =~ %r{windows}
    step 'Add pdk to path on Windows' do
      on(workstation,'cmd.exe /C setx PATH "%PATH%;C:\\Program\ Files\\Puppet\ Labs\\DevelopmentKit\\bin" /M')
    end
  end

  step 'Check rspec is ready' do
    on(workstation, "#{run_rspec(workstation)} --version") do |outcome|
      assert_match(%r{[0-9\.]*}, outcome.stdout, 'rspec --version outputs some version number')
    end
  end
end
