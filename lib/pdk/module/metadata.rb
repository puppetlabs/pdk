require 'json'

module PDK
  module Module
    class Metadata

      attr_accessor :data

      DEFAULTS = {
        'name'          => nil,
        'version'       => nil,
        'author'        => nil,
        'summary'       => '',
        'license'       => 'Apache-2.0',
        'source'        => '',
        'project_page'  => nil,
        'issues_url'    => nil,
        'dependencies'  => Set.new.freeze,
        'data_provider' => nil,
        'operatingsystem_support' => [
          {
            "operatingsystem" => "Debian",
            "operatingsystemrelease" => [ "8" ]
          },
          {
            "operatingsystem" => "RedHat",
            "operatingsystemrelease" => [ "7.0" ]
          },
          {
            "operatingsystem" => "Ubuntu",
            "operatingsystemrelease" => [ "16.04" ]
          },
          {
            "operatingsystem" => "Windows",
            "operatingsystemrelease" => [ "2016" ]
          },
        ]
      }

      def initialize(params = {})
        @data = DEFAULTS.dup
        update!(params) if params
      end

      def self.from_file(metadata_json_path)
        unless File.file?(metadata_json_path)
          raise ArgumentError, _("'%{file}' does not exist or is not a file") % {file: metadata_json_path}
        end

        unless File.readable?(metadata_json_path)
          raise ArgumentError, _("Unable to open '%{file}' for reading") % {file: metadata_json_path}
        end

        begin
          data = JSON.parse(File.read(metadata_json_path))
        rescue JSON::JSONError => e
          raise ArgumentError, _("Invalid JSON in metadata.json: %{msg}") % {msg: e.message}
        end

        new(data)
      end

      def update!(data)
        # TODO: validate all data
        process_name(data) if data['name']
        @data.merge!(data)
        self
      end

      def to_json
        JSON.pretty_generate(@data)
      end

      private

      # Do basic validation and parsing of the name parameter.
      def process_name(data)
        validate_name(data['name'])
        author, module_name = data['name'].split(/[-\/]/, 2)

        data['author'] ||= author if @data['author'] == DEFAULTS['author']
      end

      # Validates that the given module name is both namespaced and well-formed.
      def validate_name(name)
        return if name =~ /\A[a-z0-9]+[-\/][a-z][a-z0-9_]*\Z/i

        namespace, modname = name.split(/[-\/]/, 2)
        modname = :namespace_missing if namespace == ''

        err = case modname
        when nil, '', :namespace_missing
          "the field must be a dash-separated username and module name"
        when /[^a-z0-9_]/i
          "the module name contains non-alphanumeric (or underscore) characters"
        when /^[^a-z]/i
          "the module name must begin with a letter"
        else
          "the namespace contains non-alphanumeric characters"
        end

        raise ArgumentError, "Invalid 'name' field in metadata.json: #{err}"
      end
    end
  end
end
