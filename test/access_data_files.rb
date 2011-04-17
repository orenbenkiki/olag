require "olag/data_files"
require "test/spec"

# Test accessing data files packages with the gem.
class TestAccessDataFiles < Test::Unit::TestCase

  def test_access_data_file
    File.exist?(Olag::DataFiles.expand_path("olag/data_files.rb")).should == true
  end

  def test_access_missing_file
    Olag::DataFiles.expand_path("no-such-file").should == "no-such-file"
  end

end
