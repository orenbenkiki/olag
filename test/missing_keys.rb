require "olag/core_ext/hash"
require "test/spec"

# Test accessing missing keys as members.
class TestMissingKeys < ::Test::Unit::TestCase

  def test_read_missing_key
    {}.missing.should == nil
  end

  def test_set_missing_key
    hash = {}
    hash.missing = "value"
    hash.missing.should == "value"
  end

end
