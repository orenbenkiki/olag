require "fileutils"
require "tempfile"

module Test

  # Mix-in for tests that write a temporary disk file.
  module WithTempfile

    # Create a temporary file on the disk. The file will be automatically
    # removed when the test is done.
    def write_tempfile(path, content, directory = ".")
      file = Tempfile.open(path, directory)
      file.write(content)
      file.close(false)
      (@tempfiles ||= []) << file
      return file.path
    end

    # Create a temporary directory on the disk. The directory will be
    # automatically removed when the test is done. This is very useful for
    # complex file tests that can't use FakeFS.
    def create_tempdir(directory = ".")
      (file = Tempfile.open("dir", directory)).close(true)
      (@tempfiles ||= []) << file
      File.delete(path = file.path)
      Dir.mkdir(path)
      return path
    end

    # Aliasing methods needs to be deferred to when the module is included and
    # be executed in the context of the class.
    def self.included(base)
      base.class_eval do

        alias_method :tempfile_original_teardown, :teardown

        # Automatically clean up the temporary files when the test is done.
        def teardown
          tempfile_original_teardown
          (@tempfiles || []).each do |tempfile|
            path = tempfile.path
            FileUtils.rm_rf(path) if File.exist?(path)
          end
        end

      end
    end

  end

end
