test_name 'Archive test results'
require 'pdk/pdk_helper.rb'

step 'Archive rspec results' do
  archive_file_from(workstation, "#{target_dir}/results.out")
end
