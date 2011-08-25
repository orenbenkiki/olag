require "fileutils"
require "fakefs/safe"

module Test

  # Mix-in for tests that use the FakeFS fake file system.
  module WithFakeFS

    # Create and write into a file on the fake file system.
    def write_fake_file(path, content = nil, &block)
      directory = File.dirname(path)
      FileUtils.mkdir_p(directory) unless File.exists?(directory)
      File.open(path, "w") do |file|
        file.write(content) unless content.nil?
        block.call(file) unless block.nil?
      end
    end

    # Aliasing methods needs to be deferred to when the module is included and
    # be executed in the context of the class.
    def self.included(base)
      base.class_eval do

        alias_method :fakefs_original_setup, :setup

        # Automatically create an fresh fake file system for each test.
        def setup
          fakefs_original_setup
          FakeFS.activate!
          FakeFS::FileSystem.clear
        end

        alias_method :fakefs_original_teardown, :teardown

        # Automatically clean up the fake file system at the end of each test.
        def teardown
          fakefs_original_teardown
          FakeFS.deactivate!
        end

      end

    end

  end

end
