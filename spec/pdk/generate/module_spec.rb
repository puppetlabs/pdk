require 'spec_helper'

describe PDK::Generate::Module do
  context 'when gathering module information via the user interview' do
    let :metadata do
      PDK::Module::Metadata.new.update(
        'name' => 'foo-bar',
        'version' => '0.1.0',
        'dependencies' => [
          { 'name' => 'puppetlabs-stdlib', 'version_requirement' => '>= 1.0.0' }
        ]
      )
    end

    it 'populates the Metadata object based on user input' do
      allow(STDOUT).to receive(:puts)
      allow(PDK::CLI::Input).to receive(:get).and_return('2.2.0', 'William Hopper',
                                                         'Apache-2.0', 'A simple module to do some stuff.',
                                                         'github.com/whopper/bar', 'forge.puppet.com/whopper/bar',
                                                         'tickets.foo.com/whopper/bar', 'yes')

      described_class.module_interview(metadata)

      expect(metadata.data).to eq(
        'name'          => 'foo-bar',
        'version'       => '2.2.0',
        'author'        => 'William Hopper',
        'license'       => 'Apache-2.0',
        'summary'       => 'A simple module to do some stuff.',
        'source'        => 'github.com/whopper/bar',
        'project_page'  => 'forge.puppet.com/whopper/bar',
        'issues_url'    => 'tickets.foo.com/whopper/bar',
        'dependencies'  => [{ 'name' => 'puppetlabs-stdlib', 'version_requirement' => '>= 1.0.0' }],
        'data_provider' => nil
      )
    end
  end
end
