require 'spec_helper'
require 'pdk/generate/task'

describe PDK::Generate::Task do
  subject(:generator) { instance }

  let(:instance) { described_class.new(context, given_name, options) }
  let(:context) { PDK::Context::Module.new(module_dir, module_dir) }
  let(:module_name) { 'test_module' }
  let(:module_dir) { '/tmp/test_module' }
  let(:options) { {} }
  let(:expected_name) { given_name }

  before do
    allow(instance).to receive(:module_name).and_return(module_name)
  end

  shared_examples 'it generates an object file' do
    it 'writes the object file into the correct location' do
      expect(generator.template_files).to include('task.erb' => expected_object_path)
    end
  end

  describe '#template_files' do
    let(:given_name) { module_name }

    context 'when spec_only is true' do
      let(:options) { { spec_only: true } }

      it 'only returns spec files' do
        expect(generator.template_files.keys).to eq([])
      end
    end

    context 'when spec_only is false' do
      let(:options) { { spec_only: false } }

      it 'only returns all files' do
        expect(generator.template_files.keys).to eq(['task.erb'])
      end
    end
  end

  context 'when the task name is the same as the module name' do
    let(:given_name) { module_name }
    let(:expected_object_path) { File.join('tasks', 'init.sh') }

    include_examples 'it generates an object file'
  end

  context 'when the task name is different to the module name' do
    let(:given_name) { 'test_task' }
    let(:expected_object_path) { File.join('tasks', "#{given_name}.sh") }

    include_examples 'it generates an object file'
  end

  describe '#check_preconditions' do
    let(:given_name) { 'test_task' }
    let(:task_files) { [] }

    before do
      allow(PDK::Util::Filesystem).to receive(:glob).with(File.join(module_dir, 'tasks', "#{given_name}.*")).and_return(task_files)
    end

    context 'when no files exist for the task' do
      it 'does not raise an error' do
        expect { generator.check_preconditions }.not_to raise_error
      end
    end

    context 'when a .md file for the task already exists' do
      let(:task_files) { [File.join(module_dir, 'tasks', "#{given_name}.md")] }

      it 'does not raise an error' do
        expect { generator.check_preconditions }.not_to raise_error
      end
    end

    context 'when a .conf file for the task already exists' do
      let(:task_files) { [File.join(module_dir, 'tasks', "#{given_name}.conf")] }

      it 'does not raise an error' do
        expect { generator.check_preconditions }.not_to raise_error
      end
    end

    context 'when a file with any other extension exists' do
      let(:task_files) { [File.join(module_dir, 'tasks', "#{given_name}.ps1")] }

      it 'raises ExitWithError' do
        expect do
          generator.check_preconditions
        end.to raise_error(PDK::CLI::ExitWithError, %r{a task named '#{given_name}' already exists}i)
      end
    end
  end

  describe '#non_template_files' do
    let(:given_name) { 'test_task' }

    context 'when no description is provided in the options' do
      let(:options) { {} }

      it 'writes the metadata with a sample description' do
        expected_content = {
          'puppet_task_version' => 1,
          'supports_noop' => false,
          'description' => 'A short description of this task',
          'parameters' => {},
        }

        expect(generator.non_template_files).to include('tasks/test_task.json' => JSON.pretty_generate(expected_content))
      end
    end

    context 'when a description is provided in the options' do
      let(:options) { { description: 'This is a test task' } }

      it 'writes the metadata with a sample description' do
        expected_content = {
          'puppet_task_version' => 1,
          'supports_noop' => false,
          'description' => 'This is a test task',
          'parameters' => {},
        }

        expect(generator.non_template_files).to include('tasks/test_task.json' => JSON.pretty_generate(expected_content))
      end
    end
  end
end
