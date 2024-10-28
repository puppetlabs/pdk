require 'spec_helper_acceptance'
require 'fileutils'

describe 'pdk validate puppet', :module_command do
  let(:epp_spinner_text) { /checking puppet EPP syntax/i }
  let(:syntax_spinner_text) { /checking puppet manifest syntax/i }
  let(:lint_spinner_text) { /checking puppet manifest style/i }

  include_context 'with a fake TTY'

  init_pp = File.join('manifests', 'init.pp')
  example_pp = File.join('manifests', 'example.pp')

  context 'when run inside of a module' do
    include_context 'in a new module', 'validate_puppet_module'

    context 'with no .pp files' do
      describe command('pdk validate puppet --format text:stdout --format junit:report.xml') do
        its(:exit_status) { is_expected.to eq(0) }
        its(:stderr) { is_expected.not_to match(epp_spinner_text) }
        its(:stderr) { is_expected.not_to match(syntax_spinner_text) }
        its(:stderr) { is_expected.not_to match(lint_spinner_text) }
        its(:stderr) { is_expected.to match(/no files matching.*found to validate/i) }

        describe file('report.xml') do
          its(:content) { is_expected.to contain_valid_junit_xml }
          its(:content) { is_expected.to have_junit_testcase.in_testsuite('puppet-epp').that_was_skipped }
          its(:content) { is_expected.to have_junit_testcase.in_testsuite('puppet-syntax').that_was_skipped }
          its(:content) { is_expected.to have_junit_testcase.in_testsuite('puppet-lint').that_was_skipped }
        end
      end
    end

    context 'with a parsable file and no style problems' do
      before(:all) do
        File.open(init_pp, 'w') do |f|
          f.puts <<~EOS
            # foo
            class foo {
            }
          EOS
        end
      end

      after(:all) do
        FileUtils.rm(init_pp)
      end

      describe command('pdk validate puppet --format text:stdout --format junit:report.xml') do
        its(:exit_status) { is_expected.to eq(0) }
        its(:stderr) { is_expected.not_to match(epp_spinner_text) }
        its(:stderr) { is_expected.to match(syntax_spinner_text) }
        its(:stderr) { is_expected.to match(lint_spinner_text) }
        its(:stderr) { is_expected.to match(/no files matching.*found to validate/i) }

        describe file('report.xml') do
          its(:content) { is_expected.to contain_valid_junit_xml }
          its(:content) { is_expected.to have_junit_testsuite('puppet-epp') }
          its(:content) { is_expected.to have_junit_testsuite('puppet-syntax') }
          its(:content) { is_expected.to have_junit_testsuite('puppet-lint') }
        end
      end
    end

    context 'with a parsable file that has syntax warnings' do
      before(:all) do
        File.open(init_pp, 'w') do |f|
          f.puts <<~EOS
            # foo
            class foo {
              notify { 'this should raise a warning':
                message => "because of \\[\\] escape characters",
              }
            }
          EOS
        end
      end

      after(:all) do
        FileUtils.rm(init_pp)
      end

      describe command('pdk validate puppet --format text:stdout --format junit:report.xml') do
        its(:exit_status) { is_expected.to eq(1) | eq(256) }
        its(:stderr) { is_expected.not_to match(epp_spinner_text) }
        its(:stderr) { is_expected.to match(syntax_spinner_text) }
        its(:stderr) { is_expected.to match(lint_spinner_text) }

        its(:stdout) { is_expected.to match(/\(warning\):.*Unrecognized escape sequence '\\\['/i) }
        its(:stdout) { is_expected.to match(/\(warning\):.*Unrecognized escape sequence '\\\]'/i) }

        describe file('report.xml') do
          its(:content) { is_expected.to contain_valid_junit_xml }

          its(:content) do
            is_expected.to have_junit_testsuite('puppet-syntax').with_attributes(
              'failures' => eq(2),
              'tests' => eq(2)
            )
          end

          its(:content) do
            is_expected.to have_junit_testcase.in_testsuite('puppet-syntax').with_attributes(
              'classname' => 'puppet-syntax',
              'name' => a_string_starting_with(init_pp)
            ).that_failed(
              'type' => a_string_matching(/warning/i),
              'message' => a_string_matching(/unrecognized escape sequence '\\\['/i)
            )
          end

          its(:content) do
            is_expected.to have_junit_testcase.in_testsuite('puppet-syntax').with_attributes(
              'classname' => 'puppet-syntax',
              'name' => a_string_starting_with(init_pp)
            ).that_failed(
              'type' => a_string_matching(/warning/i),
              'message' => a_string_matching(/unrecognized escape sequence '\\\]'/i)
            )
          end

          its(:content) do
            is_expected.to have_junit_testsuite('puppet-lint').with_attributes(
              'failures' => a_value > 0,
              'tests' => a_value > 0
            )
          end

          its(:content) do
            is_expected.to have_junit_testcase.in_testsuite('puppet-lint').with_attributes(
              'classname' => a_string_starting_with('puppet-lint'),
              'name' => a_string_starting_with(init_pp)
            ).that_failed(
              'type' => a_string_matching(/warning/i),
              'message' => a_string_matching(/double quoted string containing no variables/i)
            )
          end
        end
      end
    end

    context 'with a deep file and windows paths', if: Gem.win_platform? do
      before(:all) do
        FileUtils.mkdir_p(File.join('manifests', 'test'))
        File.open(File.join('manifests', 'test', 'test.pp'), 'w') do |f|
          f.puts 'class win_path::test::test {}'
        end
      end

      after(:all) do
        FileUtils.rm_rf(File.join('manifests', 'test'))
      end

      describe command('pdk validate puppet manifests\test') do
        its(:exit_status) { is_expected.to eq(0) }
      end
    end

    context 'with lots of files' do
      before(:all) do
        FileUtils.mkdir_p(File.join('manifests', 'dump'))
        (1..5000).each do |num|
          File.open(File.join('manifests', 'dump', "file#{num}.pp"), 'w') do |f|
            f.puts "# file#{num}\nclass file_dump::dump::file#{num} {}"
          end
        end
      end

      after(:all) do
        FileUtils.rm_rf(File.join('manifests', 'dump'))
      end

      describe command('pdk validate puppet') do
        its(:exit_status) { is_expected.to eq(0) }
        its(:stderr) { is_expected.to match(/no files matching.*found to validate/i) }
      end
    end

    context 'with a parsable file and some style warnings' do
      before(:all) do
        File.open(init_pp, 'w') do |f|
          f.puts <<-EOS.gsub(/^ {10}/, '')
            # pdk_in_gemfile
            class pdk_in_gemfile {}
          EOS
        end
      end

      after(:all) do
        FileUtils.rm(init_pp)
      end

      describe command('pdk validate puppet --format text:stdout --format junit:report.xml') do
        its(:exit_status) { is_expected.to eq(1) | eq(256) }
        its(:stdout) { is_expected.to match(/\(warning\):.*indent should be 0 chars and is 2.*\(#{Regexp.escape(init_pp)}.+\)/i) }
        its(:stderr) { is_expected.not_to match(epp_spinner_text) }
        its(:stderr) { is_expected.to match(syntax_spinner_text) }
        its(:stderr) { is_expected.to match(lint_spinner_text) }

        describe file('report.xml') do
          its(:content) { is_expected.to contain_valid_junit_xml }

          its(:content) do
            is_expected.to have_junit_testsuite('puppet-syntax').with_attributes(
              'failures' => eq(0),
              'tests' => eq(1)
            )
          end

          its(:content) do
            is_expected.to have_junit_testcase.in_testsuite('puppet-syntax').with_attributes(
              'classname' => 'puppet-syntax',
              'name' => init_pp
            ).that_passed
          end

          its(:content) do
            is_expected.to have_junit_testsuite('puppet-lint').with_attributes(
              'failures' => eq(1),
              'tests' => eq(1)
            )
          end

          its(:content) do
            is_expected.to have_junit_testcase.in_testsuite('puppet-lint').with_attributes(
              'classname' => 'puppet-lint.strict_indent',
              'name' => a_string_starting_with(init_pp)
            ).that_failed
          end
        end
      end
    end

    context 'with a syntax failure' do
      before(:all) do
        File.open(init_pp, 'w') do |f|
          f.puts <<~EOS
            # foo
            class foo {
              Fails here because of gibberish
            }
          EOS
        end
      end

      after(:all) do
        FileUtils.rm(init_pp)
      end

      describe command('pdk validate puppet --format text:stdout --format junit:report.xml') do
        its(:exit_status) { is_expected.not_to eq(0) }
        # Note that these stderr tests are a little fragile due to execution order
        its(:stderr) { is_expected.not_to match(epp_spinner_text) }
        its(:stderr) { is_expected.to match(syntax_spinner_text) }
        its(:stderr) { is_expected.to match(lint_spinner_text) }

        its(:stdout) { is_expected.to match(/\(error\):.*This Name has no effect/i) }
        its(:stdout) { is_expected.to match(/\(error\):.*This Type-Name has no effect/i) }
        its(:stdout) { is_expected.to match(/\(error\):.*Language validation logged 2 errors/i) }

        describe file('report.xml') do
          its(:content) { is_expected.to contain_valid_junit_xml }

          its(:content) do
            is_expected.to have_junit_testsuite('puppet-syntax').with_attributes(
              'failures' => eq(3),
              'tests' => eq(3)
            )
          end

          its(:content) do
            is_expected.to have_junit_testcase.in_testsuite('puppet-syntax').with_attributes(
              'classname' => 'puppet-syntax',
              'name' => a_string_starting_with(init_pp)
            ).that_failed(
              'type' => 'Error',
              'message' => a_string_matching(/This Name has no effect/i)
            )
          end

          its(:content) do
            is_expected.to have_junit_testcase.in_testsuite('puppet-syntax').with_attributes(
              'classname' => 'puppet-syntax',
              'name' => a_string_starting_with(init_pp)
            ).that_failed(
              'type' => 'Error',
              'message' => a_string_matching(/This Type-Name has no effect/i)
            )
          end
        end
      end
    end

    context 'with a parsable file and some errors' do
      before(:all) do
        File.open(example_pp, 'w') do |f|
          f.puts '# some documentation'
          f.puts 'class foo::bar'
        end
      end

      after(:all) do
        FileUtils.rm(example_pp)
      end

      describe command('pdk validate puppet --format text:stdout --format junit:report.xml') do
        its(:exit_status) { is_expected.not_to eq(0) }
        its(:stdout) { is_expected.to match(/Syntax error at end of input/i) }
        its(:stderr) { is_expected.not_to match(epp_spinner_text) }
        its(:stderr) { is_expected.to match(syntax_spinner_text) }
        its(:stderr) { is_expected.to match(lint_spinner_text) }

        describe file('report.xml') do
          its(:content) { is_expected.to contain_valid_junit_xml }

          its(:content) do
            is_expected.to have_junit_testsuite('puppet-syntax').with_attributes(
              'failures' => eq(1),
              'tests' => eq(1)
            )
          end

          its(:content) do
            is_expected.to have_junit_testcase.in_testsuite('puppet-syntax').with_attributes(
              'classname' => 'puppet-syntax',
              'name' => a_string_starting_with(example_pp)
            ).that_failed
          end
        end
      end

      context 'when validating specific files' do
        clean_pp = File.join('manifests', 'clean.pp')

        before(:all) do
          File.open(clean_pp, 'w') do |f|
            f.puts '# some documentation'
            f.puts 'class foo::clean {}'
          end
        end

        after(:all) do
          FileUtils.rm(clean_pp)
        end

        describe command("pdk validate puppet --format text:stdout --format junit:report.xml #{clean_pp}") do
          its(:exit_status) { is_expected.to eq(0) }
          its(:stderr) { is_expected.not_to match(epp_spinner_text) }
          its(:stderr) { is_expected.to match(syntax_spinner_text) }
          its(:stderr) { is_expected.to match(lint_spinner_text) }

          describe file('report.xml') do
            its(:content) { is_expected.to contain_valid_junit_xml }

            its(:content) do
              is_expected.to have_junit_testsuite('puppet-syntax').with_attributes(
                'failures' => eq(0),
                'tests' => eq(1)
              )
            end

            its(:content) do
              is_expected.to have_junit_testcase.in_testsuite('puppet-syntax').with_attributes(
                'classname' => 'puppet-syntax',
                'name' => a_string_starting_with(clean_pp)
              ).that_passed
            end

            its(:content) do
              is_expected.to have_junit_testsuite('puppet-lint').with_attributes(
                'failures' => eq(0),
                'tests' => eq(1)
              )
            end

            its(:content) do
              is_expected.to have_junit_testcase.in_testsuite('puppet-lint').with_attributes(
                'classname' => 'puppet-lint',
                'name' => a_string_starting_with(clean_pp)
              ).that_passed
            end
          end
        end
      end

      context 'when validating specific directories' do
        another_problem_pp = File.join('manifests', 'bar', 'baz.pp')
        another_problem_dir = File.dirname(another_problem_pp)

        before(:all) do
          FileUtils.mkdir_p(another_problem_dir)
          File.open(another_problem_pp, 'w') do |f|
            f.puts 'class foo::bar::whoops'
          end
        end

        after(:all) do
          FileUtils.rm_rf(another_problem_dir)
        end

        describe command("pdk validate puppet --format text:stdout --format junit:report.xml #{another_problem_dir}") do
          its(:exit_status) { is_expected.not_to eq(0) }
          its(:stderr) { is_expected.not_to match(epp_spinner_text) }
          its(:stderr) { is_expected.to match(syntax_spinner_text) }
          its(:stderr) { is_expected.to match(lint_spinner_text) }
          its(:stdout) { is_expected.to match(/#{Regexp.escape(another_problem_pp)}/) }
          its(:stdout) { is_expected.not_to match(/#{Regexp.escape(example_pp)}/) }

          describe file('report.xml') do
            its(:content) { is_expected.to contain_valid_junit_xml }

            its(:content) do
              is_expected.to have_junit_testsuite('puppet-syntax').with_attributes(
                'failures' => eq(1),
                'tests' => eq(1)
              )
            end

            its(:content) do
              is_expected.to have_junit_testcase.in_testsuite('puppet-syntax').with_attributes(
                'classname' => a_string_starting_with('puppet-syntax'),
                'name' => a_string_starting_with(another_problem_pp)
              ).that_failed
            end

            its(:content) do
              is_expected.not_to have_junit_testcase.in_testsuite('puppet-lint').with_attributes(
                'classname' => a_string_starting_with('puppet-lint'),
                'name' => a_string_starting_with(example_pp)
              )
            end
          end
        end
      end
    end

    context 'when auto-correcting manifest style problems' do
      before(:all) do
        File.open(example_pp, 'w') do |f|
          f.puts 'notify { "test": }'
        end
      end

      after(:all) do
        FileUtils.rm(example_pp)
      end

      describe command('pdk validate puppet --auto-correct') do
        its(:exit_status) { is_expected.to eq(0) }
        its(:stdout) { is_expected.to match(/\(corrected\):.*double quoted string.*\(#{Regexp.escape(example_pp)}.*\)/i) }
      end

      describe command('pdk validate puppet') do
        its(:exit_status) { is_expected.to eq(0) }
        its(:stderr) { is_expected.to match(/no files matching.*found to validate/i) }
      end
    end
  end
end
