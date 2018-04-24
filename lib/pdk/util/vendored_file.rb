require 'pdk/util'
require 'net/https'
require 'openssl'
require 'fileutils'

module PDK
  module Util
    class VendoredFile
      class DownloadError < StandardError; end

      HTTP_ERRORS = [
        EOFError,
        Errno::ECONNRESET,
        Errno::EINVAL,
        Errno::ECONNREFUSED,
        Net::HTTPBadResponse,
        Net::HTTPHeaderSyntaxError,
        Net::ProtocolError,
        Timeout::Error,
      ].freeze

      attr_reader :file_name
      attr_reader :url

      def initialize(file_name, url)
        @file_name = file_name
        @url = url
      end

      def read
        return File.read(package_vendored_path) if PDK::Util.package_install?
        return File.read(gem_vendored_path) if File.file?(gem_vendored_path)

        content = download_file
        FileUtils.mkdir_p(File.dirname(gem_vendored_path))
        File.open(gem_vendored_path, 'w') do |fd|
          fd.write(content)
        end
        content
      end

      private

      def download_file
        PDK.logger.debug _('%{file_name} was not found in the cache, downloading it from %{url}.') % {
          file_name: file_name,
          url:       url,
        }

        uri = URI.parse(url)
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true
        # TODO: Get rid of this, possible workaround:
        # https://github.com/glennsarti/dev-tools/blob/master/RubyCerts.ps1
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE if Gem.win_platform?
        request = Net::HTTP::Get.new(uri.request_uri)
        response = http.request(request)

        unless response.code == '200'
          raise DownloadError, _('Unable to download %{url}. %{code}: %{message}.') % {
            url:     url,
            code:    response.code,
            message: response.message,
          }
        end

        response.body
      rescue *HTTP_ERRORS => e
        raise DownloadError, _('Unable to download %{url}. Check internet connectivity and try again. %{error}') % {
          error: e,
        }
      end

      def package_vendored_path
        @package_vendored_path ||= File.join(PDK::Util.package_cachedir, file_name)
      end

      def gem_vendored_path
        @gem_vendored_path ||= File.join(PDK::Util.cachedir, PDK::VERSION, file_name)
      end
    end
  end
end
