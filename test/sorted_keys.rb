require "olag/hash_sorted_yaml"
require "test/spec"

# An uncomparable class. Keys of this class will cause the Hash to be emitted
# in string sort order.
class Uncomparable

  def initialize(value)
    @value = value
  end

  def to_yaml(opts = {})
    return @value.to_yaml(opts)
  end

  def to_s
    return @value.to_s
  end

  %w(<=> < <= >= >).each do |operator|
    define_method(operator) { raise "Prevent operator: #{operator}" }
  end

end

# An uncomparable class that can't be converted to a string. Keys of this class
# will cause the Hash to be emitted in unsorted order.
class Unsortable < Uncomparable

  def to_s
    raise "Prevent conversion to string as well."
  end

end

# Test sorting keys of YAML generated from Hash tables.
class TestSortedKeys < ::Test::Unit::TestCase

  SORTED_NUMERICALLY = <<-EOF.unindent
    ---
    2: 2
    4: 4
    11: 1
    33: 3
  EOF

  SORTED_LEXICOGRAPHICALLY = <<-EOF.unindent
    ---
    11: 1
    2: 2
    33: 3
    4: 4
  EOF

  def test_sortable_keys
    { 2 => 2, 4 => 4, 11 => 1, 33 => 3 }.to_yaml.gsub(/ +$/, "").should == SORTED_NUMERICALLY
  end

  def test_uncomparable_keys
    { Uncomparable.new(11) => 1, 2 => 2, 33 => 3, 4 => 4 }.to_yaml.gsub(/ +$/, "").should == SORTED_LEXICOGRAPHICALLY
  end

  def test_unsortable_keys
    yaml_should_not = { Unsortable.new(11) => 1, 2 => 2, 33 => 3, 4 => 4 }.to_yaml.gsub(/ +$/, "").should.not
    yaml_should_not == SORTED_NUMERICALLY
    yaml_should_not == SORTED_LEXICOGRAPHICALLY
  end

end
