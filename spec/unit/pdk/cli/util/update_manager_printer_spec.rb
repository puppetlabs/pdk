require 'spec_helper'
require 'pdk/cli/util/update_manager_printer'

describe PDK::CLI::Util::UpdateManagerPrinter do
  subject(:print_summary) { described_class.print_summary(update_manager, summary_options) }

  let(:summary_options) { {} }
  let(:updated_files) { {} }
  let(:update_manager) do
    manager = PDK::Module::UpdateManager.new

    updated_files[:add_file]&.each { |path| manager.add_file(path, 'content') }
    updated_files[:modify_file]&.each { |path| manager.modify_file(path, 'new content') }
    updated_files[:remove_file]&.each { |path| manager.remove_file(path) }

    manager
  end

  before do
    allow(PDK::Report.default_target).to receive(:puts)

    # Mock the updated_files so the update_manager can pretend to read and diff them
    unless updated_files.nil?
      (updated_files[:modify_file] || []).each do |file|
        allow(PDK::Util::Filesystem).to receive(:readable?).with(file).and_return(true)
        allow(PDK::Util::Filesystem).to receive(:read_file).with(file).and_return('old content')
        allow(update_manager).to receive(:unified_diff).with(file, anything, anything).and_return('This is a diff')
      end

      (updated_files[:remove_file] || []).each do |file|
        allow(PDK::Util::Filesystem).to receive(:exist?).with(file).and_return(true)
      end
    end
  end

  shared_examples 'a summary printer' do |filename, future_tense, past_tense|
    it 'prints the files to be updated' do
      expect(PDK::Report.default_target).to receive(:puts).with(/#{filename}/)
      print_summary
    end

    it 'prints the summary category using future tense' do
      expect(PDK::Report.default_target).to receive(:puts).with(/-#{future_tense}-/i)
      print_summary
    end

    context 'when setting the :tense option to :past' do
      let(:summary_options) { { tense: :past } }

      it 'prints the summary category using past tense' do
        expect(PDK::Report.default_target).to receive(:puts).with(/-#{past_tense}-/i)
        print_summary
      end
    end
  end

  context 'given no updates' do
    it 'does not print anything' do
      expect(PDK::Report.default_target).not_to receive(:puts)
      print_summary
    end
  end

  context 'given additional files' do
    let(:updated_files) { { add_file: ['filename_to_add'] } }

    it_behaves_like 'a summary printer', 'filename_to_add', 'Files to be added', 'Files added'
  end

  context 'given modified files' do
    let(:updated_files) { { modify_file: ['filename_to_modify'] } }

    it_behaves_like 'a summary printer', 'filename_to_modify', 'Files to be modified', 'Files modified'
  end

  context 'given deleted files' do
    let(:updated_files) { { remove_file: ['filename_to_remove'] } }

    it_behaves_like 'a summary printer', 'filename_to_remove', 'Files to be removed', 'Files removed'
  end
end
