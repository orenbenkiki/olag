module Olag

  module Test

    # Mix-in for tests that write a temporary disk file.
    module TestWithTempfile

      # Create a temporary file on the disk. The file will be automatically
      # removed when the test is done.
      def write_tempfile(path, content)
        file = Tempfile.open(path, ".")
        file.write(content)
        file.close(false)
        (@tempfiles ||= []) << (path = file.path)
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
            @tempfiles ||= []
            @tempfiles.each do |tempfile|
              File.delete(tempfile) if File.exist?(tempfile)
            end
          end

        end

      end
    end

  end

end
