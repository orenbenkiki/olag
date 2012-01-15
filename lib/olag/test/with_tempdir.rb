require "olag/test/with_tempfile"

module Test

  # Mix-in for tests that run applications in a temporary directory. This
  # assumes that the test class has already mixed-in the WithTempfile mix-in.
  module WithTempdir

    # Aliasing methods needs to be deferred to when the module is included and
    # be executed in the context of the class.
    def self.included(base)
      base.class_eval do

        alias_method :tempdir_original_setup, :setup

        # Create a temporary directory for the run and percompute the standard
        # I/O file names in it.
        def setup
          tempdir_original_setup
          @tempdir = create_tempdir
          @stdout = @tempdir + "/stdout"
          @stdin = @tempdir + "/stdin"
          @stderr = @tempdir + "/stderr"
        end

      end
    end

  end

end
