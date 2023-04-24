# frozen_string_literal: true

module OS
  # Os detection: Are we on Windows?
  def self.windows?
    (/cygwin|mswin|mingw|bccwin|wince|emx/ =~ RUBY_PLATFORM) != nil
  end
end

# Patch childprocess so that it is Ruby 3 compliant.
# This could be removed if the following PR is ever merged
# and released:
# https://github.com/enkessler/childprocess/pull/185
module ChildProcess
  class << self
    def build(*args)
      case os
      when :macosx, :linux, :solaris, :bsd, :cygwin, :aix
        if posix_spawn?
          Unix::PosixSpawnProcess.new(*args)
        elsif jruby?
          JRuby::Process.new(*args)
        else
          Unix::ForkExecProcess.new(*args)
        end
      when :windows
        Windows::Process.new(*args)
      else
        raise Error, "unsupported platform #{platform_name.inspect}"
      end
    end
  end

  class AbstractProcess
    def initialize(*args)
      raise ArgumentError, "all arguments must be String: #{args.inspect}" unless args.all?(String)

      @args        = args
      @started     = false
      @exit_code   = nil
      @io          = nil
      @cwd         = nil
      @detach      = false
      @duplex      = false
      @leader      = false
      @environment = {}
    end
  end

  if OS.windows?
    module Windows
      module Lib
        extend FFI::Library
        def self.msvcrt_name
          RbConfig::CONFIG['RUBY_SO_NAME'][/msvc\w+/] || 'ucrtbase'
        end

        ffi_lib 'kernel32', msvcrt_name
        ffi_convention :stdcall

        # We have to redefine the function declarations so that they are available
        # with the patched ffi_lib.
        enum :wait_status, [
          :wait_object_0,  0, # rubocop:disable Naming/VariableNumber
          :wait_timeout,   0x102,
          :wait_abandoned, 0x80,
          :wait_failed,    0xFFFFFFFF
        ]

        #
        # BOOL WINAPI CreateProcess(
        #   __in_opt     LPCTSTR lpApplicationName,
        #   __inout_opt  LPTSTR lpCommandLine,
        #   __in_opt     LPSECURITY_ATTRIBUTES lpProcessAttributes,
        #   __in_opt     LPSECURITY_ATTRIBUTES lpThreadAttributes,
        #   __in         BOOL bInheritHandles,
        #   __in         DWORD dwCreationFlags,
        #   __in_opt     LPVOID lpEnvironment,
        #   __in_opt     LPCTSTR lpCurrentDirectory,
        #   __in         LPSTARTUPINFO lpStartupInfo,
        #   __out        LPPROCESS_INFORMATION lpProcessInformation
        # );
        #

        attach_function :create_process, :CreateProcessW, [
          :pointer,
          :buffer_inout,
          :pointer,
          :pointer,
          :bool,
          :ulong,
          :pointer,
          :pointer,
          :pointer,
          :pointer
        ], :bool

        #
        #   DWORD WINAPI FormatMessage(
        #   __in      DWORD dwFlags,
        #   __in_opt  LPCVOID lpSource,
        #   __in      DWORD dwMessageId,
        #   __in      DWORD dwLanguageId,
        #   __out     LPTSTR lpBuffer,
        #   __in      DWORD nSize,
        #   __in_opt  va_list *Arguments
        # );
        #

        attach_function :format_message, :FormatMessageA, [
          :ulong,
          :pointer,
          :ulong,
          :ulong,
          :pointer,
          :ulong,
          :pointer
        ], :ulong

        attach_function :close_handle, :CloseHandle, [:pointer], :bool

        #
        # HANDLE WINAPI OpenProcess(
        #   __in  DWORD dwDesiredAccess,
        #   __in  BOOL bInheritHandle,
        #   __in  DWORD dwProcessId
        # );
        #

        attach_function :open_process, :OpenProcess, [:ulong, :bool, :ulong], :pointer

        #
        # HANDLE WINAPI CreateJobObject(
        #   _In_opt_  LPSECURITY_ATTRIBUTES lpJobAttributes,
        #   _In_opt_  LPCTSTR lpName
        # );
        #

        attach_function :create_job_object, :CreateJobObjectA, [:pointer, :pointer], :pointer

        #
        # BOOL WINAPI AssignProcessToJobObject(
        #   _In_  HANDLE hJob,
        #   _In_  HANDLE hProcess
        # );

        attach_function :assign_process_to_job_object, :AssignProcessToJobObject, [:pointer, :pointer], :bool

        #
        # BOOL WINAPI SetInformationJobObject(
        #   _In_  HANDLE hJob,
        #   _In_  JOBOBJECTINFOCLASS JobObjectInfoClass,
        #   _In_  LPVOID lpJobObjectInfo,
        #   _In_  DWORD cbJobObjectInfoLength
        # );
        #

        attach_function :set_information_job_object, :SetInformationJobObject, [:pointer, :int, :pointer, :ulong], :bool

        #
        #
        # DWORD WINAPI WaitForSingleObject(
        #   __in  HANDLE hHandle,
        #   __in  DWORD dwMilliseconds
        # );
        #

        attach_function :wait_for_single_object, :WaitForSingleObject, [:pointer, :ulong], :wait_status, blocking: true

        #
        # BOOL WINAPI GetExitCodeProcess(
        #   __in   HANDLE hProcess,
        #   __out  LPDWORD lpExitCode
        # );
        #

        attach_function :get_exit_code, :GetExitCodeProcess, [:pointer, :pointer], :bool

        #
        # BOOL WINAPI GenerateConsoleCtrlEvent(
        #   __in  DWORD dwCtrlEvent,
        #   __in  DWORD dwProcessGroupId
        # );
        #

        attach_function :generate_console_ctrl_event, :GenerateConsoleCtrlEvent, [:ulong, :ulong], :bool

        #
        # BOOL WINAPI TerminateProcess(
        #   __in  HANDLE hProcess,
        #   __in  UINT uExitCode
        # );
        #

        attach_function :terminate_process, :TerminateProcess, [:pointer, :uint], :bool

        #
        # intptr_t _get_osfhandle(
        #    int fd
        # );
        #

        attach_function :get_osfhandle, :_get_osfhandle, [:int], :intptr_t

        #
        # int _open_osfhandle (
        #    intptr_t osfhandle,
        #    int flags
        # );
        #

        attach_function :open_osfhandle, :_open_osfhandle, [:pointer, :int], :int

        # BOOL WINAPI SetHandleInformation(
        #   __in  HANDLE hObject,
        #   __in  DWORD dwMask,
        #   __in  DWORD dwFlags
        # );

        attach_function :set_handle_information, :SetHandleInformation, [:pointer, :ulong, :ulong], :bool

        # BOOL WINAPI GetHandleInformation(
        #   __in   HANDLE hObject,
        #   __out  LPDWORD lpdwFlags
        # );

        attach_function :get_handle_information, :GetHandleInformation, [:pointer, :pointer], :bool

        # BOOL WINAPI CreatePipe(
        #   __out     PHANDLE hReadPipe,
        #   __out     PHANDLE hWritePipe,
        #   __in_opt  LPSECURITY_ATTRIBUTES lpPipeAttributes,
        #   __in      DWORD nSize
        # );

        attach_function :create_pipe, :CreatePipe, [:pointer, :pointer, :pointer, :ulong], :bool

        #
        # HANDLE WINAPI GetCurrentProcess(void);
        #

        attach_function :current_process, :GetCurrentProcess, [], :pointer

        #
        # BOOL WINAPI DuplicateHandle(
        #   __in   HANDLE hSourceProcessHandle,
        #   __in   HANDLE hSourceHandle,
        #   __in   HANDLE hTargetProcessHandle,
        #   __out  LPHANDLE lpTargetHandle,
        #   __in   DWORD dwDesiredAccess,
        #   __in   BOOL bInheritHandle,
        #   __in   DWORD dwOptions
        # );
        #

        attach_function :_duplicate_handle, :DuplicateHandle, [
          :pointer,
          :pointer,
          :pointer,
          :pointer,
          :ulong,
          :bool,
          :ulong
        ], :bool
      end
    end
  end
end
