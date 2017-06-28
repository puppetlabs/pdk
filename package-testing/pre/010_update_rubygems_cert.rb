test_name 'Update rubygems cert (if Windows)'
require 'pdk/pdk_helper'

skip_test 'Only need to do this on Windows' unless workstation.platform =~ %r{windows}

step 'Get current rubygems cert' do
  # TODO: do not depend on internet connectivity to get this file
  on(workstation, 'curl -O https://raw.githubusercontent.com/rubygems/rubygems/master/lib/rubygems/ssl_certs/index.rubygems.org/GlobalSignRootCA.pem')
end

step 'Move cert to pdk cert folder' do
  on(workstation, "cp GlobalSignRootCA.pem #{pdk_rubygems_cert_dir(workstation)}")
end
