require 'ffi'
require 'pdk/util/windows/string'

module PDK::Util::Windows::APITypes
  module ::FFI::Library
    def attach_function_private(*args)
      attach_function(*args)
      private args[0]
    end
  end

  class ::FFI::Pointer
    def self.from_string_to_wide_string(str, &_block)
      str = PDK::Util::Windows::String.wide_string(str)
      FFI::MemoryPointer.new(:byte, str.bytesize) do |ptr|
        # uchar here is synonymous with byte
        ptr.put_array_of_uchar(0, str.bytes.to_a)

        yield ptr
      end

      # ptr has already had free called, so nothing to return
      nil
    end

    def read_wide_string(char_length, dst_encoding = Encoding::UTF_8, encode_options = {})
      # char_length is number of wide chars (typically excluding NULLs), *not* bytes
      str = get_bytes(0, char_length * 2).force_encoding('UTF-16LE')
      str.encode(dst_encoding, str.encoding, **encode_options)
    rescue StandardError => e
      PDK.logger.debug 'Unable to convert value %{string} to encoding %{encoding} due to %{error}' % {
        string:   str.dump,
        encoding: dst_encoding,
        error:    e.inspect,
      }
      raise
    end

    def read_arbitrary_wide_string_up_to(max_char_length = 512, null_terminator = :single_null, encode_options = {})
      unless [:single_null, :double_null].include?(null_terminator)
        raise ArgumentError,
              'Unable to read wide strings with %{null_terminator} terminal nulls' % { null_terminator: null_terminator }
      end

      terminator_width = (null_terminator == :single_null) ? 1 : 2
      reader_method = (null_terminator == :single_null) ? :get_uint16 : :get_uint32

      # Look for the null_terminator; if found, read up to that null
      # (exclusive)
      (0...max_char_length - terminator_width).each do |i|
        return read_wide_string(i, Encoding::UTF_8, encode_options) if send(reader_method, (i * 2)).zero?
      end

      # String is longer than the max, read just up to the max
      read_wide_string(max_char_length, Encoding::UTF_8, encode_options)
    end
  end

  # FFI Types
  # https://github.com/ffi/ffi/wiki/Types

  # Windows - Common Data Types
  # https://msdn.microsoft.com/en-us/library/cc230309.aspx

  # Windows Data Types
  # https://msdn.microsoft.com/en-us/library/windows/desktop/aa383751(v=vs.85).aspx

  FFI.typedef :uint32, :dword
  # buffer_inout is similar to pointer (platform specific), but optimized for buffers
  FFI.typedef :buffer_inout, :lpwstr
  # buffer_in is similar to pointer (platform specific), but optimized for CONST read only buffers
  FFI.typedef :buffer_in, :lpcwstr
  # 8 bits per byte
  FFI.typedef :uchar, :byte
  FFI.typedef :uint16, :wchar

  # FFI bool can be only 1 byte at times,
  # Win32 BOOL is a signed int, and is always 4 bytes, even on x64
  # https://blogs.msdn.com/b/oldnewthing/archive/2011/03/28/10146459.aspx
  FFI.typedef :int32, :win32_bool
end
