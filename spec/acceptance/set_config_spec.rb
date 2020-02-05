# require 'spec_helper_acceptance'

# describe 'pdk set config' do
#   include_context 'with a fake TTY'

#   shared_examples 'a saved configuration file' do |new_content|
#     it 'saves the setting' do
#       subject.exit_status # Force the command to run if not already
#       expect(File).to exist(@fake_answer_file.path)

#       actual_content = File.open(@fake_answer_file.path, 'rb:utf-8') { |f| f.read }
#       expect(actual_content).to eq(new_content)
#     end
#   end

#   context 'when run outside of a module' do
#     describe command('pdk set config') do
#       its(:exit_status) { is_expected.to_not eq 0 }
#       its(:stdout) { is_expected.to have_no_output }
#       its(:stderr) { is_expected.to match(%r{Configuration name is required}) }
#     end

#     context 'with a setting that does not exist' do
#       describe command('pdk set config user.module_defaults.mock value') do
#         include_context 'with a fake answer file'

#         its(:exit_status) { is_expected.to eq 0 }
#         its(:stdout) { is_expected.to have_no_output }
#         its(:stderr) { is_expected.to match(%r{Set 'user.module_defaults.mock' to 'value'}) }

#         it_behaves_like 'a saved configuration file', "{\n  \"mock\": \"value\"\n}\n"
#       end
#     end

#     context 'with a conflicting setting, not forced' do
#       describe command('pdk set config user.module_defaults.mock value') do
#         include_context 'with a fake answer file', { 'mock' => [] }

#         its(:exit_status) { is_expected.to eq 0 }
#         its(:stdout) { is_expected.to have_no_output }
#         its(:stderr) { is_expected.to match(%r{Set 'user.module_defaults.mock' to 'value'}) }

#         it_behaves_like 'a saved configuration file', "{\n  \"mock\": \"value\"\n}\n"
#       end
#     end
#     # describe command('pdk set config user.analytics.disabled') do
#     #   its(:exit_status) { is_expected.to eq 0 }
#     #   # This setting, and only, this setting should appear in output
#     #   its(:stdout) { is_expected.to eq("true\n") }
#     #   its(:stderr) { is_expected.to have_no_output }
#     # end

#     # describe command('pdk set config user.analytics') do
#     #   its(:exit_status) { is_expected.to eq 0 }
#     #   # There should be two configuration items returned
#     #   its(:stdout) { expect(is_expected.target.split("\n").count).to eq(2) }
#     #   its(:stdout) do
#     #     result = is_expected.target.split("\n").sort
#     #     expect(result[0]).to match('user.analytics.disabled=true')
#     #     expect(result[1]).to match(%r{user.analytics.user-id=.+})
#     #   end
#     #   its(:stderr) { is_expected.to have_no_output }
#     # end

#     # describe command('pdk set config does.not.exist') do
#     #   its(:exit_status) { is_expected.not_to eq(0) }
#     #   its(:stdout) { is_expected.to have_no_output }
#     #   its(:stderr) { is_expected.to match(%r{does\.not\.exist}) }
#     # end
#   end
# end
