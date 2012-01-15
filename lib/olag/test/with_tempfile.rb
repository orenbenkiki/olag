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
      (@tempfiles ||= []) << (path = file.path)
      return path
    end

    # Create a temporary directory on the disk. The directory will be
    # automatically removed when the test is done. This is very useful for
    # complex file tests that can't use FakeFS.
    def create_tempdir(directory = ".")
      file = Tempfile.open("dir", directory)
      (@tempfiles ||= []) << (path = file.path)
      File.delete(path)
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
            FileUtils.rm_rf(tempfile) if File.exist?(tempfile)
          end
        end

      end
    end

  end

end
