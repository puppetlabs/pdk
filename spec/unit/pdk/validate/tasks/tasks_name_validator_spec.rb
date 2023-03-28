require 'spec_helper'
require 'pdk/validate/tasks/tasks_name_validator'

describe PDK::Validate::Tasks::TasksNameValidator do
  describe '.name' do
    subject { described_class.new.name }

    it { is_expected.to eq('task-name') }
  end

  describe '.spinner_text' do
    subject(:spinner_text) { described_class.new.spinner_text }

    it { is_expected.to match(%r{checking task name}i) }
  end

  describe '.validate_target' do
    subject(:return_value) { described_class.new.validate_target(report, target) }

    let(:report) { PDK::Report.new }

    after(:each) do
      return_value
    end

    context 'when a task name starts with a number' do
      let(:target) { File.join('tasks', '0_do_a_thing.sh') }

      it 'adds a failure event to the report' do
        expect(report).to receive(:add_event).with({
                                                     file: target,
                                                     source: 'task-name',
                                                     state: :failure,
                                                     severity: 'error',
                                                     message: described_class::INVALID_TASK_MSG,
                                                   })
      end

      it 'returns 1' do
        expect(return_value).to eq(1)
      end
    end

    context 'when a task name contains uppercase characters' do
      let(:target) { File.join('tasks', 'aTask.ps1') }

      it 'adds a failure event to the report' do
        expect(report).to receive(:add_event).with({
                                                     file: target,
                                                     source: 'task-name',
                                                     state: :failure,
                                                     severity: 'error',
                                                     message: described_class::INVALID_TASK_MSG,
                                                   })
      end

      it 'returns 1' do
        expect(return_value).to eq(1)
      end
    end

    context 'when the task name is valid' do
      let(:target) { File.join('tasks', 'a_task.rb') }

      it 'adds a passing event to the report' do
        expect(report).to receive(:add_event).with({
                                                     file: target,
                                                     source: 'task-name',
                                                     state: :passed,
                                                     severity: 'ok',
                                                   })
      end

      it 'returns 0' do
        expect(return_value).to eq(0)
      end
    end
  end
end
