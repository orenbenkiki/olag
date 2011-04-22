require "fileutils"
require "olag/errors"
require "olag/globals"
require "olag/string_unindent.rb"
require "olag/version"
require "optparse"

module Olag

  # Base class for Olag applications.
  class Application

    # Create a Olag application.
    def initialize(is_test = nil)
      @errors = Errors.new
      @is_test = !!is_test
    end

    # Run the Olag application, returning its status.
    def run(*arguments, &block)
      parse_options
      yield(*arguments) if block_given?
      return print_errors
    rescue ExitException => exception
      return exception.status
    end

    # Execute a block with an overriden ARGV, typically for running an
    # application.
    def self.with_argv(argv)
      return Globals.without_changes do
        ARGV.replace(argv)
        yield
      end
    end

  protected

    # Parse the command line options of the program.
    def parse_options
      parser = OptionParser.new do |options|
        (@options = options).banner = banner + "\n\nOPTIONS:\n\n"
        define_flags
      end
      parser.parse!
      parse_arguments
    end

    # Parse remaining command-line file arguments. This is expected to be
    # overriden by the concrete application sub-class. By default assumes there
    # are no such arguments.
    def parse_arguments
      return if ARGV.size == 0
      $stderr.puts("#{$0}: Expects no command line file arguments.")
      exit(1)
    end

    # Define application flags. This is expected to be overriden by the
    # concrete application sub-class.
    def define_flags
      define_help_flag
      define_version_flag
      define_redirect_flag("$stdout", "output", "w")
      define_redirect_flag("$stderr", "error", "w")
      #! Most scripts do not use this, but they can add it.
      #! define_redirect_flag("$stdin", "input", "r")
    end

    # Define the standard help flag.
    def define_help_flag
      @options.on("-h", "--help", "Print this help message and exit.") do
        puts(@options)
        print_additional_help
        exit(0)
      end
    end

    # Print additional help message. This includes both the command line file
    # arguments, if any, and a short description of the program.
    def print_additional_help
      arguments_name, arguments_description = arguments
      puts(format("    %-33s%s", arguments_name, arguments_description)) if arguments_name
      print("\nDESCRIPTION:\n\n")
      print(description)
    end

    # Return the banner line of the help message. This is expected to be
    # overriden by the concrete application sub-class. By default returns the
    # path name of thje executed program.
    def banner
      return $0
    end

    # Return the name and description of any final command-line file arguments,
    # if any. This is expected to be overriden by the concrete application
    # sub-class. By default, assume there are no final command-line file
    # arguments (however, `parse_options` does not enforce this by default).
    def arguments
      return nil, nil
    end

    # Return a short description of the program. This is expected to be
    # overriden by the concrete application sub-class. By default, provide 
    def description
      return "Sample description\n"
    end

    # Define the standard version flag.
    def define_version_flag
      version_number = version
      @options.on("-v", "--version", "Print the version number (#{version_number}) and exit.") do
        puts("#{$0}: Version: #{version_number}")
        exit(0)
      end
    end

    # Define a flag redirecting one of the standard IO files.
    def define_redirect_flag(variable, name, mode)
      @options.on("-#{name[0,1]}", "--#{name} FILE", String, "Redirect standard #{name} to a file.") do |file|
        eval("#{variable} = Application::redirect_file(#{variable}, file, mode)")
      end
    end

    # Redirect a standard file.
    def self.redirect_file(default, file, mode)
      return default if file.nil? || file == "-"
      FileUtils.mkdir_p(File.dirname(File.expand_path(file))) if mode == "w"
      return File.open(file, mode)
    end

    # Return the application's version. This is expected to be overriden by the
    # concrete application sub-class. In the base class, we just return Olag's
    # version which only useful for Olag's tests.
    def version
      return Olag::VERSION
    end

    # Print all the collected errors.
    def print_errors
      @errors.each do |error|
        $stderr.puts(error)
      end
      return @errors.size
    end

    # Exit the application, unless we are running inside a test.
    def exit(status)
      Kernel.exit(status) unless @is_test
      raise ExitException.new(status)
    end

  end

  # Exception used to exit when running inside tests.
  class ExitException < Exception

    # The exit status.
    attr_reader :status

    # Create a new exception to indicate exiting the program with some status.
    def initialize(status)
      @status = status
    end

  end

end
