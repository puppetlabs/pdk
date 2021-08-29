require 'pdk'

module PDK
  module Validate
    module Puppet
      class PuppetPlanSyntaxValidator < PuppetSyntaxValidator
        def name
          'puppet-syntax-plan'
        end

        def pattern
          contextual_pattern('plans/**/*.pp')
        end

        def pattern_ignore
        end

        def spinner_text_for_targets(_targets)
          _('Checking Puppet plan syntax (%{pattern}).') % { pattern: pattern.join(' ') }
        end

        def parse_options(targets)
          # Due to PDK-1266 we need to run `puppet parser validate` with an empty
          # modulepath. On *nix, Ruby treats `/dev/null` as an empty directory
          # however it doesn't do so with `NUL` on Windows. The workaround for
          # this to ensure consistent behaviour is to create an empty temporary
          # directory and use that as the modulepath.
          ['parser', 'validate', '--tasks', '--config', null_file, '--modulepath', validate_tmpdir].concat(targets)
        end

        def invoke(report)
          super
        ensure
          remove_validate_tmpdir
        end

        def validate_tmpdir
          require 'tmpdir'

          @validate_tmpdir ||= Dir.mktmpdir('puppet-parser-validate-plan')
        end

        def remove_validate_tmpdir
          return unless @validate_tmpdir
          return unless PDK::Util::Filesystem.directory?(@validate_tmpdir)

          PDK::Util::Filesystem.remove_entry_secure(@validate_tmpdir)
          @validate_tmpdir = nil
        end

      end
    end
  end
end
