require 'pdk/util/bundler'
require 'spec_helper'
require 'rspec-benchmark'

RSpec.describe 'bundler performance' do
  include RSpec::Benchmark::Matchers

  let(:bundler) { PDK::Util::Bundler::BundleHelper.new }
  let(:gemfile) { File.join(FIXTURES_DIR, 'Gemfile_simple') }
  let(:gemfile_lock) { File.join(FIXTURES_DIR, 'Gemfile_simple.lock') }

  before(:each) do
    # Allow us to mock/stub/expect calls to the internal bundle helper.
    FileUtils.rm_f(gemfile_lock)
    allow(bundler).to receive(:gemfile_lock).and_return(gemfile_lock)
    allow(bundler).to receive(:gemfile).and_return(gemfile)
    allow(bundler).to receive(:gemfile?).and_return(true)
    allow(FileUtils).to receive(:mv).with(gemfile_lock, anything)
    allow(FileUtils).to receive(:mv).with(anything, gemfile_lock, force: true)
  end

  describe 'windows', if: OS.windows? do
    it '#installed?' do
      expect { bundler.installed? }.to perform_under(50).ms
    end

    it '#install!' do
      expect { bundler.install! }.to perform_under(2500).ms
    end

    it '#update_lock!' do
      expect { bundler.update_lock! }.to perform_under(5000).ms
    end
  end

  describe 'unix', if: OS.unix? do
    it '#installed?' do
      expect { bundler.installed? }.to perform_under(20).ms
    end

    it '#install!' do
      expect { bundler.install! }.to perform_under(2200).ms
    end

    it '#update_lock!' do
      expect { bundler.update_lock! }.to perform_under(2900).ms
    end
  end
end
