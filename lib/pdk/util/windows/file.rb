require 'pdk/util/windows'

module PDK::Util::Windows::File
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
          raise 'Failed to call GetLongPathName'
        end

        converted = converted_ptr.read_wide_string(buffer_size - 1)
      end
    end

    converted
  end
  module_function :get_long_pathname

  ffi_convention :stdcall

  # https://msdn.microsoft.com/en-us/library/windows/desktop/aa364980(v=vs.85).aspx
  # DWORD WINAPI GetLongPathName(
  #   _In_  LPCTSTR lpszShortPath,
  #   _Out_ LPTSTR  lpszLongPath,
  #   _In_  DWORD   cchBuffer
  # );
  ffi_lib :kernel32
  attach_function :GetLongPathNameW, [:lpcwstr, :lpwstr, :dword], :dword
end
