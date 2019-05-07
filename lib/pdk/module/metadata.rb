require 'json'
require 'pdk/util/filesystem'

module PDK
  module Module
    class Metadata
      attr_accessor :data

      include PDK::Util::Filesystem

      # rubocop:disable Style/WordArray
      OPERATING_SYSTEMS = {
        'RedHat based Linux' => [
          {
            'operatingsystem'        => 'CentOS',
            'operatingsystemrelease' => ['6', '7'],
          },
          {
            'operatingsystem'        => 'OracleLinux',
            'operatingsystemrelease' => ['6', '7'],
          },
          {
            'operatingsystem'        => 'RedHat',
            'operatingsystemrelease' => ['6', '7', '8'],
          },
          {
            'operatingsystem'        => 'Scientific',
            'operatingsystemrelease' => ['6', '7'],
          },
        ],
        'Debian based Linux' => [
          {
            'operatingsystem'        => 'Debian',
            'operatingsystemrelease' => ['8', '9'],
          },
          {
            'operatingsystem'        => 'Ubuntu',
            'operatingsystemrelease' => ['16.04', '18.04'],
          },
        ],
        'Fedora' => {
          'operatingsystem'        => 'Fedora',
          'operatingsystemrelease' => ['28', '29', '30'],
        },
        'OSX' => {
          'operatingsystem'        => 'Darwin',
          'operatingsystemrelease' => ['16'],
        },
        'SLES' => {
          'operatingsystem'        => 'SLES',
          'operatingsystemrelease' => ['11', '12', '15'],
        },
        'Solaris' => {
          'operatingsystem'        => 'Solaris',
          'operatingsystemrelease' => ['11'],
        },
        'Windows' => {
          'operatingsystem'        => 'windows',
          'operatingsystemrelease' => ['2008 R2', '2012 R2', '10'],
        },
        'Arch Linux' => {
          'operatingsystem'        => 'Archlinux',
        },
      }.freeze
      # rubocop:enable Style/WordArray

      DEFAULT_OPERATING_SYSTEMS = [
        'RedHat based Linux',
        'Debian based Linux',
        'Windows',
      ].freeze

      DEFAULTS = {
        'name'          => nil,
        'version'       => '0.1.0',
        'author'        => nil,
        'summary'       => '',
        'license'       => 'Apache-2.0',
        'source'        => '',
        'project_page'  => nil,
        'issues_url'    => nil,
        'dependencies'  => [],
        'data_provider' => nil,
        'operatingsystem_support' => DEFAULT_OPERATING_SYSTEMS.map { |os_name|
          OPERATING_SYSTEMS[os_name]
        }.flatten,
        'requirements' => [
          { 'name' => 'puppet', 'version_requirement' => '>= 4.10.0 < 7.0.0' },
        ],
      }.freeze

      def initialize(params = {})
        @data = DEFAULTS.dup
        update!(params) if params
      end

      def self.from_file(metadata_json_path)
        if metadata_json_path.nil?
          raise ArgumentError, _('Cannot read metadata from file: no path to file was given.')
        end

        unless File.file?(metadata_json_path)
          raise ArgumentError, _("'%{file}' does not exist or is not a file.") % { file: metadata_json_path }
        end

        unless File.readable?(metadata_json_path)
          raise ArgumentError, _("Unable to open '%{file}' for reading.") % { file: metadata_json_path }
        end

        begin
          data = JSON.parse(File.read(metadata_json_path))
        rescue JSON::JSONError => e
          raise ArgumentError, _('Invalid JSON in metadata.json: %{msg}') % { msg: e.message }
        end

        data['template-url'] = PDK::Util::TemplateURI.default_template_uri.metadata_format if PDK::Util.package_install? && data['template-url'] == PDK::Util::TemplateURI::PACKAGED_TEMPLATE_KEYWORD
        new(data)
      end

      def update!(data)
        # TODO: validate all data
        process_name(data) if data['name']
        @data.merge!(data)
        self
      end

      def to_json
        JSON.pretty_generate(@data.dup.delete_if { |_key, value| value.nil? })
      end

      def write!(path)
        write_file(path, to_json)
      end

      def forge_ready?
        missing_fields.empty?
      end

      def interview_for_forge!
        PDK::Generate::Module.module_interview(self, only_ask: missing_fields)
      end

      def validate_puppet_version_requirement!
        msgs = {
          no_reqs:       _('Module metadata does not contain any requirements.'),
          no_puppet_req: _('Module metadata does not contain a "puppet" requirement.'),
          no_puppet_ver: _('The "puppet" requirement in module metadata does not specify a "version_requirement".'),
        }

        raise ArgumentError, msgs[:no_reqs] unless @data.key?('requirements')
        raise ArgumentError, msgs[:no_puppet_req] if puppet_requirement.nil?
        raise ArgumentError, msgs[:no_puppet_ver] unless puppet_requirement.key?('version_requirement')
        raise ArgumentError, msgs[:no_puppet_ver] if puppet_requirement['version_requirement'].empty?
      end

      def puppet_requirement
        @data['requirements'].find do |r|
          r.key?('name') && r['name'] == 'puppet'
        end
      end

      def missing_fields
        fields = DEFAULTS.keys - %w[data_provider requirements dependencies]
        fields.select { |key| @data[key].nil? || @data[key].empty? }
      end

      private

      # Do basic validation and parsing of the name parameter.
      def process_name(data)
        validate_name(data['name'])
        author, modname = data['name'].split(%r{[-/]}, 2)
        data['name'] = [author, modname].join('-')

        data['author'] ||= author if @data['author'] == DEFAULTS['author']
      end

      # Validates that the given module name is both namespaced and well-formed.
      def validate_name(name)
        return if name =~ %r{\A[a-z0-9]+[-\/][a-z][a-z0-9_]*\Z}i

        namespace, modname = name.split(%r{[-/]}, 2)
        modname = :namespace_missing if namespace == ''

        err = case modname
              when nil, '', :namespace_missing
                _('Field must be a dash-separated user name and module name.')
              when %r{[^a-z0-9_]}i
                _('Module name must contain only alphanumeric or underscore characters.')
              when %r{^[^a-z]}i
                _('Module name must begin with a letter.')
              else
                _('Namespace must contain only alphanumeric characters.')
              end

        raise ArgumentError, _("Invalid 'name' field in metadata.json: %{err}") % { err: err }
      end
    end
  end
end
