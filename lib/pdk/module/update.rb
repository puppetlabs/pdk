require 'pdk/module/convert'

module PDK
  module Module
    class Update < Convert
      GIT_DESCRIBE_PATTERN = %r{\A(?<base>.+?)-(?<additional_commits>\d+)-g(?<sha>.+)\Z}

      def run
        stage_changes!

        PDK.logger.info(update_message)

        print_summary
        full_report('update_report.txt') unless update_manager.changes[:modified].empty?

        if !update_manager.changes? && get_sha(current_version) == get_sha(new_version)
          PDK.logger.info _('This module is already up to date with version %{version} of the template.') % {
            version: new_version,
          }
          return
        end

        return if noop?

        unless force?
          message = _('Do you want to continue and make these changes to your module?')
          return unless PDK::CLI::Util.prompt_for_yes(message)
        end

        if needs_bundle_update?
          update_manager.remove_file('Gemfile.lock')
          update_manager.remove_file(File.join('.bundle', 'config'))
        end

        update_manager.sync_changes!

        PDK::Util::Bundler.ensure_bundle! if needs_bundle_update?

        print_result 'Update completed'
      end

      def module_metadata
        @module_metadata ||= PDK::Module::Metadata.from_file('metadata.json')
      rescue ArgumentError => e
        raise PDK::CLI::ExitWithError, e.message
      end

      def template_url
        @template_url ||= module_metadata.data['template-url']
      end

      def current_version
        @current_version ||= describe_ref_to_s(current_template_version)
      end

      def new_version
        @new_version ||= fetch_remote_version(new_template_version)
      end

      private

      def get_sha(version_ref)
        version_ref.split('@')[-1]
      end

      def current_template_version
        @current_template_version ||= module_metadata.data['template-ref']
      end

      def describe_ref_to_s(describe_ref)
        data = GIT_DESCRIBE_PATTERN.match(describe_ref)

        return data if data.nil?

        if data[:base].start_with?('heads/')
          "#{data[:base].gsub(%r{^heads/}, '')}@#{data[:sha]}"
        elsif data[:sha]
          "#{data[:base]}@#{data[:sha]}"
        else
          data[:base]
        end
      end

      def new_template_version
        PDK::Util.default_template_ref
      end

      def fetch_remote_version(version)
        data = GIT_DESCRIBE_PATTERN.match(current_template_version)

        return version if data.nil?

        branch = version.partition('/').last if version.include?('/')
        sha_length = data[:sha].length - 1
        "#{branch}@#{PDK::Util::Git.ls_remote(template_url, "refs/heads/#{branch}")[0..sha_length]}"
      end

      def update_message
        format_string = if template_url == PDK::Util.puppetlabs_template_url
                          _('Updating %{module_name} using the default template, from %{current_version} to %{new_version}')
                        else
                          _('Updating %{module_name} using the template at %{template_url}, from %{current_version} to %{new_version}')
                        end

        format_string % {
          module_name:     module_metadata.data['name'],
          template_url:    template_url,
          current_version: current_version,
          new_version:     new_version,
        }
      end
    end
  end
end
