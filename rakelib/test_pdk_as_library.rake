require 'English'

task :test_pdk_as_library do
  spec_dir = File.expand_path(File.join(__dir__, '..', 'spec'))

  Dir[File.join(spec_dir, 'unit', '**', '*_spec.rb')].each do |spec_file|
    system("bundle exec rspec #{spec_file}")

    raise unless $CHILD_STATUS.success?
  end
end
