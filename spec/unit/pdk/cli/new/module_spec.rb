require 'spec_helper'

describe 'Running `pdk new module`' do
  subject { PDK::CLI.instance_variable_get(:@new_module_cmd) }

  context 'when not passed a module name' do
    it do
      expect {
        PDK::CLI.run(%w[new module])
      }.to raise_error(SystemExit) { |error|
        expect(error.status).to eq(1)
      }.and output(a_string_matching(%r{^USAGE\s+pdk new module}m)).to_stdout
    end
  end

  context 'when passed an invalid module name' do
    it 'informs the user that the module name is invalid' do
      expect(logger).to receive(:error).with(a_string_matching(%r{'123test'.*not.*valid module name}m))

      expect {
        PDK::CLI.run(%w[new module 123test])
      }.to raise_error(SystemExit) { |error|
        expect(error.status).to eq(1)
      }
    end
  end

  context 'when passed a valid module name' do
    let(:module_name) { 'test123' }

    it 'validates the module name' do
      expect(PDK::Generate::Module).to receive(:invoke).with(hash_including(module_name: module_name))
      expect(logger).to receive(:info).with("Creating new module: #{module_name}")
      PDK::CLI.run(['new', 'module', module_name])
    end

    context 'and a target directory' do
      let(:target_dir) { 'target' }

      it 'passes the target directory to PDK::Generate::Module.invoke' do
        expect(PDK::Generate::Module).to receive(:invoke).with(hash_including(module_name: module_name, target_dir: target_dir))
        expect(logger).to receive(:info).with("Creating new module: #{module_name}")
        PDK::CLI.run(['new', 'module', module_name, target_dir])
      end
    end

    context 'and the template-url option' do
      let(:template_url) { 'https://github.com/myuser/my-pdk-template' }

      it 'passes the value of the template-url option to PDK::Generate::Module.invoke' do
        expect(PDK::Generate::Module).to receive(:invoke).with(hash_including(:'template-url' => template_url))
        expect(logger).to receive(:info).with("Creating new module: #{module_name}")
        PDK::CLI.run(['new', 'module', '--template-url', template_url, module_name])
      end
    end

    context 'and the license option' do
      let(:license) { 'MIT' }

      it 'passes the value of the license option to PDK::Generate::Module.invoke' do
        expect(PDK::Generate::Module).to receive(:invoke).with(hash_including(license: license))
        expect(logger).to receive(:info).with("Creating new module: #{module_name}")
        PDK::CLI.run(['new', 'module', '--license', license, module_name])
      end
    end

    context 'and the skip-interview flag' do
      it 'passes true as the value of the skip-interview option to PDK::Generate::Module.invoke' do
        expect(PDK::Generate::Module).to receive(:invoke).with(hash_including(:'skip-interview' => true))
        expect(logger).to receive(:info).with("Creating new module: #{module_name}")
        PDK::CLI.run(['new', 'module', '--skip-interview', module_name])
      end
    end
  end
end
