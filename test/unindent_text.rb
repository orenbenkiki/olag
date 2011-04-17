require "olag/string_unindent"
require "test/spec"

# Test unindenting a multi-line text.
class TestUnindentText < ::Test::Unit::TestCase

  def test_automatic_unindent
    <<-EOF.unindent.should == "a\n  b\n"
      a
        b
    EOF
  end

  def test_invalid_unindent
    "    a\n  b\n".unindent.should == "a\n  b\n"
  end

  def test_integer_unindent
    "  a\n    b\n".unindent(1).should == " a\n   b\n"
  end

  def test_string_unindent
    "  a\n    b\n".unindent(" ").should == " a\n   b\n"
  end

end
