require 'pdk/cli/util'
require 'pdk/validate'
require 'pdk/util/bundler'
require 'pdk/cli/util/interview'
require 'pdk/cli/util/changelog_generator'
require 'pdk/module/build'

module PDK::CLI
  @release_cmd = @base_cmd.define_command do
    name 'release'
    usage _('release [options]')
    summary _('Release a module to the Puppet Forge.')

    option nil, 'force', _('Skips the prompts, builds and releases the module package.')
    option nil, 'skip_validation', _('Skips the module validation check.')
    option nil, 'skip_changelog', _('Skips the automatic changelog generation.')
    option nil, 'skip_dependency', _('Skips the module dependency check.')
    option nil, 'skip_documentation', _('Skips the documentation update.')
    option nil, 'forge_upload_url', _('Set forge upload url path.'),
           argument: :required, default: 'https://forgeapi.puppetlabs.com/v3/releases'
    option nil, 'forge_token', _('Set Forge API token.'), argument: :required, default: nil
    option false, 'skip_build', _('Skips module build.')
    option false, 'skip_push', _('Skips pushing the module to the forge.')

    run do |opts, args, _cmd|
      # Make sure build is being run in a valid module directory with a metadata.json
      PDK::CLI::Util.ensure_in_module!(
        message:   _('`pdk release` can only be run from inside a valid module with a metadata.json.'),
        log_level: :info,
      )

      args.each do |item|
        case item
        when %r{^with_version.+}
          opts[:version_number] = item.split('=')[1]
        when 'prep'
          opts[:skip_build] = true
          opts[:skip_push] = true
        when 'build'
          opts[:skip_validation] = true
          opts[:skip_changelog] = true
          opts[:skip_dependency] = true
          opts[:skip_documentation] = true
          opts[:force] = true
          opts[:skip_push] = true
        when 'push'
          opts[:skip_validation] = true
          opts[:skip_changelog] = true
          opts[:skip_dependency] = true
          opts[:skip_documentation] = true
          opts[:force] = true
          opts[:skip_build] = true
        else
          raise ArgumentError _('Unknown argument %{arg}') % { arg: item }
        end
      end

      unless opts[:force]
        prepare_interview(opts)
      end

      PDK::CLI::Util.analytics_screen_view('release', opts)

      run_validations(opts)

      module_metadata = PDK::Module::Metadata.from_file('metadata.json')

      PDK.logger.info _('Releasing %{module_name} - from version %{module_version}') % {
        module_name:    module_metadata.data['name'],
        module_version: module_metadata.data['version'],
      }

      if opts[:skip_changelog]
        PDK.logger.info _('Skipping automatic changelog generation')
        if opts[:version_number]
          PDK.logger.info _('Updating version to %{module_version}') % {
            module_version: opts[:version_number],
          }

          # Bump version in metadata file
          module_metadata.data['version'] = opts[:version_number]
          module_metadata.write!('metadata.json')
        end
      else
        new_version = 'v0.0.1'
        changelog_generator = PDK::CLI::Util::ChangelogGenerator.new
        if opts[:version_number]
          new_version = opts[:version_number]
        else
          # Use changelog generator to establish version
          PDK.logger.info _('Generating changelog to get next version number')
          changelog_generator.generate_changelog

          new_version = changelog_generator.get_next_version(module_metadata.data['version'])
        end

        PDK.logger.info _('Updating version to %{module_version}') % {
          module_version: new_version,
        }

        # Bump version in metadata file

        module_metadata.data['version'] = new_version
        module_metadata.write!('metadata.json')

        # Create new changelog with the correct version
        changelog_generator.generate_changelog
        PDK.logger.info _("New changelog generated with version #{new_version}")
      end

      if opts[:skip_documentation]
        PDK.logger.info _('Skipping documentation update for this module')
      else
        PDK.logger.info _('Updating documentation using puppet strings')
        docs_command = PDK::CLI::Exec::InteractiveCommand.new(PDK::CLI::Exec.bundle_bin, 'exec', 'puppet', 'strings', 'generate', '--format', 'markdown', '--out', 'REFERENCE.md')
        docs_command.context = :module
        result = docs_command.execute!
        PDK.logger.error _('Error updating documentation using puppet strings') if result[:exit_code] != 0
      end

      if opts[:skip_dependency]
        PDK.logger.info _('Skipping dependency-cheking on the metadata of this module')
      else
        # run dependency-checker and output dependent modules list
        PDK.logger.info _('Running dependency checker for %{module_name} - version %{module_version}') % {
          module_name:    module_metadata.data['name'],
          module_version: module_metadata.data['version'],
        }

        dep_command = PDK::CLI::Exec::Command.new('dependency-checker', 'metadata.json')
        dep_command.context = :module
        result = dep_command.execute!
        PDK.logger.error _('Error running dependecy-checker') if result[:exit_code] != 0
      end

      unless module_metadata.forge_ready?
        if opts[:force]
          PDK.logger.warn _(
            'This module is missing the following fields in the metadata.json: %{fields}. ' \
            'These missing fields may affect the visibility of the module on the Forge.',
          ) % {
            fields: module_metadata.missing_fields.join(', '),
          }
        else
          module_metadata.interview_for_forge!
          module_metadata.write!('metadata.json')
        end
      end

      if opts[:skip_build]
        PDK.logger.info _('Skipping module build')
      else
        tarball_path = build_module(opts, module_metadata)
      end
      if opts[:skip_push]
        PDK.logger.info _('Skipping module push to the Forge')
      else
        push_to_forge(opts, tarball_path)
      end
    end
  end
end

def push_to_forge(opts, tarball_path)
  unless opts[:forge_token]
    PDK.logger.error _('No forge API key set, skipping module push to the Forge')
    return nil
  end
  # TODO: Replace this code when the upload functionality is added to the forge ruby gem
  file_data = Base64.encode64(File.open(tarball_path, 'rb').read)

  PDK.logger.info _('Uploading tarball to puppet forge...')
  uri = URI(opts[:forge_upload_url])
  request = Net::HTTP::Post.new(uri.path)
  request['Authorization'] = 'Bearer ' + opts[:forge_token]
  request['Content-Type'] = 'application/json'
  data = { file: file_data }

  request.body = data.to_json

  response = Net::HTTP.start(uri.host, uri.port, use_ssl: true, verify_mode: OpenSSL::SSL::VERIFY_NONE) do |http|
    http.request(request)
  end

  if response.is_a?(Net::HTTPSuccess)
    PDK.logger.info _('Upload successful')
  else
    PDK.logger.error _('Error uploading to Puppet Forge: %{result}') % { result: response }
  end
end

def build_module(opts, module_metadata)
  builder = PDK::Module::Build.new(opts)

  unless opts[:force]
    unless builder.module_pdk_compatible?
      PDK.logger.info _('This module is not compatible with PDK, so PDK can not validate or test this build. ' \
                        'Unvalidated modules may have errors when uploading to the Forge. ' \
                        'To make this module PDK compatible and use validate features, cancel the build and run `pdk convert`.')

      unless PDK::CLI::Util.prompt_for_yes(_('Continue build without converting?'))
        PDK.logger.info _('Build cancelled; exiting.')
        exit 0
      end
    end
  end

  PDK.logger.info _('Building %{module_name} version %{module_version}') % {
    module_name:    module_metadata.data['name'],
    module_version: module_metadata.data['version'],
  }

  builder.build

  PDK.logger.info _('Build of %{package_name} has completed successfully. Built package can be found here: %{package_path}') % {
    package_name: module_metadata.data['name'],
    package_path: builder.package_file,
  }

  builder.package_file
end

def run_validations(opts)
  PDK::CLI::Util.validate_puppet_version_opts(opts)

  PDK::CLI::Util.module_version_check

  report = PDK::Report.new
  puppet_env = PDK::CLI::Util.puppet_from_opts_or_env(opts)
  PDK::Util::PuppetVersion.fetch_puppet_dev if opts[:'puppet-dev']
  PDK::Util::RubyVersion.use(puppet_env[:ruby_version])

  opts.merge!(puppet_env[:gemset])

  PDK::Util::Bundler.ensure_bundle!(puppet_env[:gemset])

  if opts[:skip_validation]
    PDK.logger.info _('Skipping module validation')
  else
    exit_code = 0
    validators = PDK::Validate.validators
    validators.each do |validator|
      validator_exit_code = validator.invoke(report, opts.dup)
      exit_code = validator_exit_code if validator_exit_code != 0
    end

    exit exit_code if exit_code != 0
  end
end

def prepare_interview(opts)
  questions = []

  unless opts[:skip_validation]
    questions << {
      name:     'validation',
      question: _('Do you want to run the module validation ?'),
      type:     :yes,
    }
  end
  unless opts[:skip_changelog]
    questions << {
      name:     'changelog',
      question: _('Do you want to run the automatic changelog generation ?'),
      type:     :yes,
    }
    questions << {
      name:     'guess_version',
      question: _('Do you want to try and set the version automatically ?'),
      type:     :yes,
    }
  end
  unless opts[:skip_dependency]
    questions << {
      name:     'dependency',
      question: _('Do you want to run the dependency-checker on this module?'),
      type:     :yes,
    }
  end
  unless opts[:skip_documentation]
    questions << {
      name:     'documentation',
      question: _('Do you want to update the documentation for this module?'),
      type:     :yes,
    }
  end
  unless opts[:skip_push]
    questions << {
      name:     'publish',
      question: _('Do you want to publish the module on the Puppet Forge?'),
      type:     :yes,
    }
  end

  prompt = TTY::Prompt.new(help_color: :cyan)
  interview = PDK::CLI::Util::Interview.new(prompt)
  interview.add_questions(questions)
  answers = interview.run

  unless answers.nil?
    opts[:skip_validation] = !answers['validation']
    opts[:skip_changelog] = !answers['changelog']
    opts[:skip_dependency] = !answers['dependency']
    opts[:skip_documentation] = !answers['documentation']

    unless answers['guess_version']
      questions = [
        {
          name:             'version',
          question:         _('Please set the module version'),
          help:             _('This value is the version that will be used in the changelog generator and building of the module.'),
          required:         true,
          validate_pattern: %r{(\*|\d+(\.\d+){0,2}(\.\*)?)$}i,
          validate_message: _('The version format should be in the format x.y.z where x represents the major version, y the minor version and z the build number.'),
        },
      ]
      interview = PDK::CLI::Util::Interview.new(prompt)
      interview.add_questions(questions)
      ver_answer = interview.run
      opts[:version_number] = ver_answer['version']
    end
    if answers['publish']
      questions = [
        {
          name:             'apikey',
          question:         _('Please set the api key(authorization token) to upload on the Puppet Forge'),
          help:             _('This value is used for authentication on the Puppet Forge to upload your module tarball.'),
          required:         true,
        },
      ]
      interview = PDK::CLI::Util::Interview.new(prompt)
      interview.add_questions(questions)
      api_answer = interview.run
      opts[:forge_token] = api_answer['apikey']
    end
  end
  answers
end
