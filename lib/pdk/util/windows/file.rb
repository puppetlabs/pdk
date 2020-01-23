require 'pdk/util/windows'

module PDK::Util::Windows::File
  #:nocov:
  # These are wrappers for system level APIs and therefore don't need to be tested
  require 'ffi'
  extend FFI::Library
  extend PDK::Util::Windows::String

  def get_long_pathname(path)
    converted = ''
    FFI::Pointer.from_string_to_wide_string(path) do |path_ptr|
      # includes terminating NULL
      buffer_size = GetLongPathNameW(path_ptr, FFI::Pointer::NULL, 0)
      FFI::MemoryPointer.new(:wchar, buffer_size) do |converted_ptr|
        if GetLongPathNameW(path_ptr, converted_ptr, buffer_size) == PDK::Util::Windows::WIN32_FALSE
          raise _('Failed to call GetLongPathName')
        end

        converted = converted_ptr.read_wide_string(buffer_size - 1)
      end
    end

    converted
  end
  module_function :get_long_pathname

  # Taken from https://github.com/puppetlabs/puppet/blob/ba4d1a1aba0095d3c70b98fea5c67434a4876a61/lib/puppet/util/windows/file.rb
  def get_short_pathname(path)
    converted = ''
    FFI::Pointer.from_string_to_wide_string(path) do |path_ptr|
      # includes terminating NULL
      buffer_size = GetShortPathNameW(path_ptr, FFI::Pointer::NULL, 0)
      FFI::MemoryPointer.new(:wchar, buffer_size) do |converted_ptr|
        if GetShortPathNameW(path_ptr, converted_ptr, buffer_size) == PDK::Util::Windows::WIN32_FALSE
          raise _('Failed to call GetShortPathName')
        end

        converted = converted_ptr.read_wide_string(buffer_size - 1)
      end
    end

    converted
  end
  module_function :get_short_pathname

  # Wraps the call to get the short path name in Windows and swallows any errors.
  #
  # @api private
  def safe_get_short_pathname(path)
    # Note that the short path detection is not fool-proof.  For example if 8.3 filename creation is disabled
    # there is no shortname to find. In that case it just returns the long name.
    #
    # Testing this is also not needed as it's just wrapping core Windows APIs
    PDK::Util::Windows::File.get_short_pathname(path)
  rescue RuntimeError => ex
    # If there are any failures detecting the short path then log a warning and return the, possibly, long path
    PDK.logger.warn(_("Failed to resolve the shortname of the path '%{path}': %{message}") %
      { path: path, message: ex.message })
    path
  end
  module_function :safe_get_short_pathname

  ffi_convention :stdcall

  # https://msdn.microsoft.com/en-us/library/windows/desktop/aa364980(v=vs.85).aspx
  # DWORD WINAPI GetLongPathName(
  #   _In_  LPCTSTR lpszShortPath,
  #   _Out_ LPTSTR  lpszLongPath,
  #   _In_  DWORD   cchBuffer
  # );
  ffi_lib :kernel32
  attach_function :GetLongPathNameW, [:lpcwstr, :lpwstr, :dword], :dword

  # https://msdn.microsoft.com/en-us/library/windows/desktop/aa364989(v=vs.85).aspx
  # DWORD WINAPI GetShortPathName(
  #   _In_  LPCTSTR lpszLongPath,
  #   _Out_ LPTSTR  lpszShortPath,
  #   _In_  DWORD   cchBuffer
  # );
  ffi_lib :kernel32
  attach_function_private :GetShortPathNameW, [:lpcwstr, :lpwstr, :dword], :dword
  #:nocov:
end
