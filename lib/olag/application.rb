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
    def run(&block)
      parse_options
      yield if block_given?
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
        @options = options
        define_flags
      end
      parser.parse!
    end

    # Define application flags. This is expected to be overriden by the
    # concrete application sub-class.
    def define_flags
      define_help_flag
      define_version_flag
      define_redirect_flag("$stdout", "output", "w")
      define_redirect_flag("$stderr", "error", "w")
      define_redirect_flag("$stdin", "input", "i")
    end

    # Define the standard help flag.
    def define_help_flag
      @options.on("-h", "--help", "Print this help message and exit.") do
        print_help_before_options
        puts(@options)
        print_help_after_options
        exit(0)
      end
    end

    # Print the part of the help message before the list of options. This is
    # expected to be overriden by the concrete application sub-class.
    def print_help_before_options
    end

    # Print the part of the help message after the list of options. This is
    # expected to be overriden by the concrete application sub-class.
    def print_help_after_options
    end

    # Define the standard version flag.
    def define_version_flag
      version_number = version
      @options.on("-v", "--version", "Print the version number #{version_number} and exit.") do
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
      return Olag.version
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
