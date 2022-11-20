require 'pdk'

module PDK
  module Util
    class VendoredFile
      class DownloadError < StandardError; end

      attr_reader :file_name
      attr_reader :url

      def initialize(file_name, url)
        @file_name = file_name
        @url = url
      end

      def read
        require 'pdk/util'
        require 'pdk/util/filesystem'

        return PDK::Util::Filesystem.read_file(package_vendored_path) if PDK::Util.package_install?
        return PDK::Util::Filesystem.read_file(gem_vendored_path) if PDK::Util::Filesystem.file?(gem_vendored_path)

        content = download_file

        # TODO: should only write if it's valid JSON
        # TODO: need a way to invalidate if out of date
        PDK::Util::Filesystem.mkdir_p(File.dirname(gem_vendored_path))
        PDK::Util::Filesystem.write_file(gem_vendored_path, content)
        content
      end

      private

      def download_file
        require 'uri'
        require 'net/https'
        require 'openssl'

        http_errors = [
          EOFError,
          Errno::ECONNRESET,
          Errno::EINVAL,
          Errno::ECONNREFUSED,
          Net::HTTPBadResponse,
          Net::HTTPHeaderSyntaxError,
          Net::ProtocolError,
          Timeout::Error,
        ]

        PDK.logger.debug '%{file_name} was not found in the cache, downloading it from %{url}.' % {
          file_name: file_name,
          url:       url,
        }

        uri = URI.parse(url)
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true
        # TODO: Get rid of this
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE if Gem.win_platform?
        request = Net::HTTP::Get.new(uri.request_uri)
        response = http.request(request)

        unless response.code == '200'
          raise DownloadError, 'Unable to download %{url}. %{code}: %{message}.' % {
            url:     url,
            code:    response.code,
            message: response.message,
          }
        end

        response.body
      rescue *http_errors => e
        raise DownloadError, 'Unable to download %{url}. Check internet connectivity and try again. %{error}' % {
          url: url,
          error: e,
        }
      end

      def package_vendored_path
        require 'pdk/util'

        @package_vendored_path ||= File.join(PDK::Util.package_cachedir, file_name)
      end

      def gem_vendored_path
        require 'pdk/util'
        require 'pdk/version'

        @gem_vendored_path ||= File.join(PDK::Util.cachedir, PDK::VERSION, file_name)
      end
    end
  end
end
