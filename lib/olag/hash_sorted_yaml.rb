require "yaml"

if RUBY_VERSION.include?("1.8")

  # Modify the hash class to emit YAML sorted keys. This is an ugly hack,
  # specifically for Ruby 1.8.*.
  class Hash

    # Provide access to the old, unsorted implementation.
    alias :unsorted_to_yaml :to_yaml

    # Return the hash in YAML format with sorted keys.
    def to_yaml(opts = {})
      YAML::quick_emit(self, opts) do |out|
        out.map(taguri, to_yaml_style) do |map|
          to_yaml_sorted_keys.each do |key|
            map.add(key, fetch(key))
          end
        end
      end
    end

    # Return the hash keys, sorted for emitting into YAML.
    def to_yaml_sorted_keys
      begin
        return keys.sort
      rescue
        return to_yaml_lexicographically_sorted_keys
      end
    end

    # Return the hash keys, sorted lexicographically for emitting into YAML.
    def to_yaml_lexicographically_sorted_keys
      begin
        return keys.sort_by {|key| key.to_s}
      rescue
        return keys
      end
    end

  end

end
