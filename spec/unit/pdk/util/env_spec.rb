require 'spec_helper'
require 'pdk/util/env'
require 'securerandom'

def on_windows
  Gem.win_platform?
end

describe PDK::Util::Env do
  before(:each) do
    ENV[env_name] = env_val
  end

  after(:each) do
    ENV.delete(env_name)
  end

  let(:env_name) { SecureRandom.hex(10) + 'ABCabc' }
  let(:env_val) { 'PDK::Util::Env test value' }
  let(:upcase_name) { env_name.upcase }
  let(:downcase_name) { env_name.upcase }

  describe '[]' do
    it 'is case insensitive on Windows platform', if: on_windows do
      expect(described_class[env_name]).to eq(env_val)
      expect(described_class[downcase_name]).to eq(env_val)
      expect(described_class[upcase_name]).to eq(env_val)
    end

    it 'is case sensitive on non-Windows platform', unless: on_windows do
      expect(described_class[env_name]).to eq(env_val)
      expect(described_class[downcase_name]).to be_nil
      expect(described_class[upcase_name]).to be_nil
    end
  end

  describe '[]=' do
    let(:new_val) { 'New PDK::Util::Env test value' }

    before(:each) do
      # Order is important here.
      ENV.delete(upcase_name)
      ENV[env_name] = env_val
      expect(described_class[env_name]).to eq(env_val)
    end

    after(:each) do
      ENV.delete(upcase_name)
    end

    it 'is case insensitive on Windows platform', if: on_windows do
      described_class[upcase_name] = new_val
      expect(described_class[env_name]).to eq(new_val)
      expect(described_class[upcase_name]).to eq(new_val)
    end

    it 'is case sensitive on non-Windows platform', unless: on_windows do
      described_class[upcase_name] = new_val
      expect(described_class[env_name]).to eq(env_val)
      expect(described_class[upcase_name]).to eq(new_val)
    end
  end

  describe '.key?' do
    let(:new_val) { 'New PDK::Util::Env test value' }

    it 'is case insensitive on Windows platform', if: on_windows do
      expect(described_class.key?(env_name)).to be true
      expect(described_class.key?(downcase_name)).to be true
      expect(described_class.key?(upcase_name)).to be true
    end

    it 'is case sensitive on non-Windows platform', unless: on_windows do
      expect(described_class.key?(env_name)).to be true
      expect(described_class.key?(downcase_name)).to be false
      expect(described_class.key?(upcase_name)).to be false
    end
  end
end
