require "olag/application"
require "olag/test"
require "test/spec"

# An application that emits an error when run.
class ErrorApplication < Olag::Application

  # Run the error application.
  def run
    super { @errors << "Oops!" }
  end

end

# Test running a Olag Application.
class TestRunApplication < Test::Unit::TestCase

  include Test::WithFakeFS

  def test_do_nothing
    Olag::Application.with_argv([]) { Olag::Application.new(true).run }.should == 0
  end

  def test_extra_arguments
    Olag::Application.with_argv(%w(-e stderr dummy)) { Olag::Application.new(true).run }.should == 1
    File.read("stderr").should.include?("Expects no command line file arguments")
  end

  def test_print_version
    Olag::Application.with_argv(%w(-o nested/stdout -v -h)) { Olag::Application.new(true).run }.should == 0
    File.read("nested/stdout").should == "#{$0}: Version: #{Olag::VERSION}\n"
  end

  def test_print_help
    Olag::Application.with_argv(%w(-o stdout -h -v)) { Olag::Application.new(true).run }.should == 0
    File.read("stdout").should.include?("DESCRIPTION:")
  end

  def test_print_errors
    Olag::Application.with_argv(%w(-e stderr)) { ErrorApplication.new(true).run }.should == 1
    File.read("stderr").should.include?("Oops!")
  end

end
