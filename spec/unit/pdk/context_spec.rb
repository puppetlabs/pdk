require 'spec_helper'
require 'pdk/context'
require 'tmpdir'
require 'fileutils'

class MockContext < PDK::Context::AbstractContext
  def initialize(context_path, prefix, parent_context = nil)
    @prefix = prefix
    @parent_context = parent_context
    @root_path = context_path
  end

  def display_name
    "a #{@prefix} context"
  end

  def parent_context # rubocop:disable Style/TrivialAccessors
    @parent_context
  end
end

describe PDK::Context do
  describe '#create' do
    subject(:context) { described_class.create(context_path) }

    let(:context_path) { nil }
    let(:puppet_module_fixture) { File.join(FIXTURES_DIR, 'puppet_module') }
    let(:control_repo_fixture) { File.join(FIXTURES_DIR, 'control_repo') }

    def expect_a_none_context(context, context_path)
      expect(context).to be_a(PDK::Context::None)
      expect(context.context_path).to eq(context_path)
      expect(context.root_path).to eq(context.root_path)
      expect(context.parent_context).to be_nil
    end

    def expect_a_module_context(context, context_path, module_root, has_parent = false)
      expect(context).to be_a(PDK::Context::Module)
      if context_path.nil?
        expect(context.context_path).not_to be_nil
      else
        expect(context.context_path).to eq(context_path) unless context_path.nil?
      end
      expect(context.root_path).to eq(module_root)
      if has_parent
        expect(context.parent_context).not_to be_a(PDK::Context::None)
      else
        expect(context.parent_context).to be_a(PDK::Context::None)
      end
    end

    def expect_a_controlrepo_context(context, context_path, repo_root)
      expect(context).to be_a(PDK::Context::ControlRepo)
      if context_path.nil?
        expect(context.context_path).not_to be_nil
      else
        expect(context.context_path).to eq(context_path) unless context_path.nil?
      end
      expect(context.root_path).to eq(repo_root)
      expect(context.parent_context).to be_a(PDK::Context::None)
    end

    context 'with a path that does not exist' do
      let(:context_path) { 'does/not/exist' }

      before(:each) do
        allow(PDK::Util::Filesystem).to receive(:directory?).with(context_path).and_return(false)
      end

      it 'returns a None Context' do
        expect_a_none_context(context, context_path)
      end
    end

    context 'with a path that does exist' do
      let(:temp_context_path) { Dir.mktmpdir }

      before(:each) do
        # Stop any deep searching past the temp directory
        parent_path = PDK::Util::Filesystem.expand_path('..', temp_context_path)
        allow(PDK::Util::Filesystem).to receive(:directory?).and_call_original
        allow(PDK::Util::Filesystem).to receive(:directory?).with(parent_path).and_return(false)
      end

      after(:each) do
        FileUtils.rm_rf(temp_context_path) if Dir.exist?(temp_context_path) # rubocop:disable PDK/DirExistPredicate,PDK/FileUtilsRMRF We need to call the real functions
      end

      context 'and is empty' do
        let(:context_path) { temp_context_path }

        it 'returns a None Context' do
          expect_a_none_context(context, temp_context_path)
        end
      end

      context 'and is a puppet module' do
        let(:puppet_module_fixture_root) { File.join(temp_context_path, 'puppet_module') }
        let(:deep_dir_path) { File.join(puppet_module_fixture_root, 'manifests', 'foo', 'bar') }

        before(:each) do
          # Copy the module
          FileUtils.cp_r(puppet_module_fixture, temp_context_path)
          # Create deep directories
          FileUtils.mkdir_p(deep_dir_path) # rubocop:disable PDK/FileUtilsMkdirP We need to call the real function
        end

        context 'in the root of the module' do
          let(:context_path) { puppet_module_fixture_root }

          it 'returns a Module Context at the module root' do
            expect_a_module_context(context, context_path, puppet_module_fixture_root)
          end
        end

        context 'in a deep directory of the module' do
          let(:context_path) { deep_dir_path }

          it 'returns a Module Context at the module root' do
            expect_a_module_context(context, context_path, puppet_module_fixture_root)
          end
        end
      end

      context 'and is a control repo' do
        let(:control_repo_fixture_root) { File.join(temp_context_path, 'control_repo') }
        let(:module_dir) { File.join(control_repo_fixture_root, 'site', 'profile', 'test') }

        before(:each) do
          # Copy the control repo
          FileUtils.cp_r(control_repo_fixture, temp_context_path)
          # Copy a module into control repo site dir
          FileUtils.cp_r(puppet_module_fixture, module_dir)
        end

        context 'in the root of the control repo' do
          let(:context_path) { control_repo_fixture_root }

          it 'returns a None Context' do
            expect_a_none_context(context, context_path)
          end
        end

        context 'in a non-module path of the control repo' do
          let(:context_path) { File.join(control_repo_fixture_root, 'data') }

          it 'returns a None Context' do
            expect_a_none_context(context, context_path)
          end
        end

        context 'in a module path of the control repo' do
          let(:context_path) { File.join(module_dir, 'manifests') }

          it 'returns a Module Context ' do
            expect_a_module_context(context, context_path, module_dir)
          end
        end

        context 'and has the controlrepo feature flag' do
          before(:each) { allow(PDK).to receive(:feature_flag?).with('controlrepo').and_return(true) }

          context 'in the root of the control repo' do
            let(:context_path) { control_repo_fixture_root }

            it 'returns a Control Repo Context at the root' do
              expect_a_controlrepo_context(context, context_path, control_repo_fixture_root)
            end
          end

          context 'in a non-module path of the control repo' do
            let(:context_path) { File.join(control_repo_fixture_root, 'data') }

            it 'returns a Control Repo Context at the root' do
              expect_a_controlrepo_context(context, context_path, control_repo_fixture_root)
            end
          end

          context 'in a module path of the control repo' do
            let(:context_path) { File.join(module_dir, 'manifests') }

            it 'returns a Module Context in a Control Repo Context' do
              expect_a_module_context(context, context_path, module_dir, true)
              expect_a_controlrepo_context(context.parent_context, nil, control_repo_fixture_root)
            end
          end
        end
      end

      context 'and is a control repo which also looks like a module' do
        # Prior to adding Control Repo support, many users added a metadata.json file to the root
        # of their Control Repo, so the PDK could be used. This tricked the PDK into thinking it
        # was a module. The PDK::Context.create method needs to deal with this correctly and detect
        # this hybrid setups as a Control Repo, not a Module.
        let(:control_repo_fixture_root) { File.join(temp_context_path, 'control_repo') }
        let(:module_dir) { File.join(control_repo_fixture_root, 'site', 'profile', 'test') }

        before(:each) do
          # Copy the control repo
          FileUtils.cp_r(control_repo_fixture, temp_context_path)
          # Copy a module into control repo site dir
          FileUtils.cp_r(puppet_module_fixture, module_dir)
          # Copy some module content into control repo dir
          FileUtils.copy_file(File.join(puppet_module_fixture, 'metadata.json'), File.join(control_repo_fixture_root, 'metadata.json'))
          FileUtils.mkdir_p(File.join(control_repo_fixture_root, 'manifests')) # rubocop:disable PDK/FileUtilsMkdirP We need to call the real function
        end

        context 'in the root of the control repo' do
          let(:context_path) { control_repo_fixture_root }

          it 'returns a Module Context ' do
            expect_a_module_context(context, context_path, control_repo_fixture_root)
          end
        end

        context 'in a non-module path of the control repo' do
          let(:context_path) { File.join(control_repo_fixture_root, 'data') }

          it 'returns a Module Context ' do
            expect_a_module_context(context, context_path, control_repo_fixture_root)
          end
        end

        context 'in a module path of the control repo' do
          let(:context_path) { File.join(module_dir, 'manifests') }

          it 'returns a Module Context in a Module Context' do
            expect_a_module_context(context, context_path, module_dir, true)
            expect_a_module_context(context.parent_context, nil, control_repo_fixture_root)
          end
        end

        context 'and has the controlrepo feature flag' do
          before(:each) { allow(PDK).to receive(:feature_flag?).with('controlrepo').and_return(true) }

          context 'in the root of the control repo' do
            let(:context_path) { control_repo_fixture_root }

            it 'returns a Control Repo Context at the root' do
              expect_a_controlrepo_context(context, context_path, control_repo_fixture_root)
            end
          end

          context 'in a non-module path of the control repo' do
            let(:context_path) { File.join(control_repo_fixture_root, 'data') }

            it 'returns a Control Repo Context at the root' do
              expect_a_controlrepo_context(context, context_path, control_repo_fixture_root)
            end
          end

          context 'in a module path of the control repo' do
            let(:context_path) { File.join(module_dir, 'manifests') }

            it 'returns a Module Context in a Control Repo Context' do
              expect_a_module_context(context, context_path, module_dir, true)
              expect_a_controlrepo_context(context.parent_context, nil, control_repo_fixture_root)
            end
          end
        end
      end
    end
  end

  describe PDK::Context::AbstractContext do
    subject(:context) { described_class.new(context_path) }

    let(:context_path) { 'somepath' }

    it 'has a root_path of context' do
      expect(context.root_path).to eq(context.context_path)
    end

    it 'remembers the context path' do
      expect(context.context_path).to eq(context_path)
    end

    it 'has a pdk_compatible? of false' do
      expect(context.pdk_compatible?).to eq(false)
    end

    it 'has a display_name of nil' do
      expect(context.display_name).to be_nil
    end

    it 'responds to parent_context' do
      expect(context).to respond_to(:parent_context)
    end

    describe '#to_debug_log' do
      let(:parent_context) { MockContext.new('path1', 'Mock1') }
      let(:child_context) { MockContext.new('path2', 'Mock2', parent_context) }
      let(:nested_context) { MockContext.new('path3', 'Mock3', child_context) }

      it 'writes to the debug log' do
        expect(PDK.logger).to receive(:debug).with(%r{Detected a Mock1 context at path1})
        parent_context.to_debug_log
      end

      it 'writes all contexts at this child and parents thereof to the debug log' do
        expect(PDK.logger).to receive(:debug).with(%r{Detected a Mock2 context at path2})
        expect(PDK.logger).to receive(:debug).with(%r{Detected a Mock1 context at path1})
        child_context.to_debug_log
      end

      it 'writes all contexts to the debug log if given a child context' do
        expect(PDK.logger).to receive(:debug).with(%r{Detected a Mock3 context at path3})
        expect(PDK.logger).to receive(:debug).with(%r{Detected a Mock2 context at path2})
        expect(PDK.logger).to receive(:debug).with(%r{Detected a Mock1 context at path1})
        nested_context.to_debug_log
      end
    end
  end
end
