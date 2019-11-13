require 'spec_helper'
require 'pdk/generate/task'

describe PDK::Generate::Task do
  subject(:generator) { described_class.new(module_dir, given_name, options) }

  subject(:target_object_path) { generator.target_object_path }

  subject(:template_data) { generator.template_data }

  let(:module_name) { 'test_module' }
  let(:module_dir) { '/tmp/test_module' }
  let(:options) { {} }
  let(:expected_name) { given_name }

  before(:each) do
    test_metadata = { 'name' => module_name }
    allow(PDK::Util).to receive(:module_metadata).and_return(test_metadata)
  end

  describe '#target_object_path' do
    subject { generator.target_object_path }

    context 'when the task name is the same as the module name' do
      let(:given_name) { module_name }

      it { is_expected.to eq(File.join(module_dir, 'tasks', 'init.sh')) }
    end

    context 'when the task name is different to the module name' do
      let(:given_name) { 'test_task' }

      it { is_expected.to eq(File.join(module_dir, 'tasks', "#{given_name}.sh")) }
    end
  end

  describe '#target_spec_path' do
    subject { generator.target_spec_path }

    let(:given_name) { 'test_task' }

    it { is_expected.to be_nil }
  end

  describe '#check_if_task_already_exists' do
    let(:given_name) { 'test_task' }
    let(:task_files) { [] }

    before(:each) do
      allow(PDK::Util::Filesystem).to receive(:glob).with(File.join(module_dir, 'tasks', "#{given_name}.*")).and_return(task_files)
    end

    context 'when no files exist for the task' do
      it 'does not raise an error' do
        expect { generator.check_if_task_already_exists }.not_to raise_error
      end
    end

    context 'when a .md file for the task already exists' do
      let(:task_files) { [File.join(module_dir, 'tasks', "#{given_name}.md")] }

      it 'does not raise an error' do
        expect { generator.check_if_task_already_exists }.not_to raise_error
      end
    end

    context 'when a .conf file for the task already exists' do
      let(:task_files) { [File.join(module_dir, 'tasks', "#{given_name}.conf")] }

      it 'does not raise an error' do
        expect { generator.check_if_task_already_exists }.not_to raise_error
      end
    end

    context 'when a file with any other extension exists' do
      let(:task_files) { [File.join(module_dir, 'tasks', "#{given_name}.ps1")] }

      it 'raises ExitWithError' do
        expect {
          generator.check_if_task_already_exists
        }.to raise_error(PDK::CLI::ExitWithError, %r{a task named '#{given_name}' already exists}i)
      end
    end
  end

  describe '#write_task_metadata' do
    let(:given_name) { 'test_task' }
    let(:metadata_file) { File.join(module_dir, 'tasks', "#{given_name}.json") }

    context 'when no description is provided in the options' do
      it 'writes the metadata with a sample description' do
        expected_content = {
          'puppet_task_version' => 1,
          'supports_noop'       => false,
          'description'         => 'A short description of this task',
          'parameters'          => {},
        }

        expect(PDK::Util::Filesystem).to receive(:write_file)
          .with(metadata_file, satisfy { |content| JSON.parse(content) == expected_content })

        generator.write_task_metadata
      end
    end

    context 'when a description is provided in the options' do
      let(:options) { { description: 'This is a test task' } }

      it 'writes the metadata with the provided description' do
        expected_content = {
          'puppet_task_version' => 1,
          'supports_noop'       => false,
          'description'         => 'This is a test task',
          'parameters'          => {},
        }

        expect(PDK::Util::Filesystem).to receive(:write_file)
          .with(metadata_file, satisfy { |content| JSON.parse(content) == expected_content })

        generator.write_task_metadata
      end
    end
  end
end
