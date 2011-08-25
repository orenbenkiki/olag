require "olag/errors"
require "olag/test"
require "test/spec"

# Test collecting errors.
class TestCollectErrors < Test::Unit::TestCase

  include Test::WithErrors
  include Test::WithFakeFS

  def test_one_error
    @errors << "Oops"
    @errors.should == [ "#{$0}: Oops" ]
  end

  def test_path_error
    @errors.in_path("foo") do
      @errors << "Oops"
      "result"
    end.should == "result"
    @errors.should == [ "#{$0}: Oops in file: foo" ]
  end

  def test_line_error
    @errors.in_path("foo") do
      @errors.at_line(1)
      @errors << "Oops"
    end
    @errors.should == [ "#{$0}: Oops in file: foo at line: 1" ]
  end

  def test_file_error
    write_fake_file("foo", "bar\n")
    @errors.in_file("foo") do
      @errors << "Oops"
      "result"
    end.should == "result"
    @errors.should == [ "#{$0}: Oops in file: foo" ]
  end

  def test_file_lines_error
    write_fake_file("foo", "bar\nbaz\n")
    @errors.in_file_lines("foo") do |line|
      @errors << "Oops" if line == "baz\n"
    end
    @errors.should == [ "#{$0}: Oops in file: foo at line: 2" ]
  end


end
