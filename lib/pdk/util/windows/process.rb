require 'pdk/util/windows'

module PDK::Util::Windows::Process
  require 'ffi'
  extend PDK::Util::Windows::String
  extend FFI::Library

  def environment_hash
    env_ptr = GetEnvironmentStringsW()

    contains_unicode_replacement = ->(string) do
      return false unless string.include?("\uFFFD")

      PDK.logger.warning "Discarding environment variable #{string} which contains invalid bytes"
      true
    end

    # pass :invalid => :replace to the Ruby String#encode to use replacement
    # characters
    pairs = env_ptr.read_arbitrary_wide_string_up_to(65_534, :double_null, invalid: :replace)
                   .split(?\x00)
                   .reject { |env_str| env_str.nil? || env_str.empty? || env_str[0] == '=' }
                   .reject { |env_str| contains_unicode_replacement.call(env_str) }
                   .map { |env_pair| env_pair.split('=', 2) }
    Hash[pairs]
  ensure
    if env_ptr && !env_ptr.null?
      if FreeEnvironmentStringsW(env_ptr) == PDK::Util::Windows::WIN32_FALSE
        PDK.logger.debug 'FreeEnvironmentStringsW memory leak'
      end
    end
  end
  module_function :environment_hash

  def set_environment_variable(name, val)
    raise ArgumentError, 'Environment variable name must not be nil or empty' if name.nil? || name.empty?

    FFI::MemoryPointer.from_string_to_wide_string(name) do |name_ptr|
      if val.nil?
        if SetEnvironmentVariableW(name_ptr, FFI::MemoryPointer::NULL) == PDK::Util::Windows::WIN32_FALSE
          raise 'Failed to remove environment variable: %{name}' % { name: name }
        end
      else
        FFI::MemoryPointer.from_string_to_wide_string(val) do |val_ptr|
          if SetEnvironmentVariableW(name_ptr, val_ptr) == PDK::Util::Windows::WIN32_FALSE
            raise 'Failed to set environment variaible: %{name}' % { name: name }
          end
        end
      end
    end
  end
  module_function :set_environment_variable

  ffi_convention :stdcall

  # https://msdn.microsoft.com/en-us/library/windows/desktop/ms683187(v=vs.85).aspx
  # LPTCH GetEnvironmentStrings(void);
  ffi_lib :kernel32
  attach_function_private :GetEnvironmentStringsW, [], :pointer

  # https://msdn.microsoft.com/en-us/library/windows/desktop/ms683151(v=vs.85).aspx
  # BOOL FreeEnvironmentStrings(
  #   _In_ LPTCH lpszEnvironmentBlock
  # );
  ffi_lib :kernel32
  attach_function_private :FreeEnvironmentStringsW, [:pointer], :win32_bool

  # https://msdn.microsoft.com/en-us/library/windows/desktop/ms686206(v=vs.85).aspx
  # BOOL WINAPI SetEnvironmentVariableW(
  #   _In_     LPCTSTR lpName,
  #   _In_opt_ LPCTSTR lpValue
  # );
  ffi_lib :kernel32
  attach_function_private :SetEnvironmentVariableW, [:lpcwstr, :lpcwstr],
                          :win32_bool
end
