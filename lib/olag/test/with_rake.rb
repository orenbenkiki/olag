module Test

  # Mix-in for tests that use Rake.
  module WithRake

    # Aliasing methods needs to be deferred to when the module is included
    # and be executed in the context of the class.
    def self.included(base)
      base.class_eval do

        alias_method :rake_original_setup, :setup

        # Automatically create a fresh Rake application.
        def setup
          rake_original_setup
          @original_rake = Rake.application
          @rake = Rake::Application.new
          Rake.application = @rake
        end

        alias_method :rake_original_teardown, :teardown

        # Automatically restore the original Rake application.
        def teardown
          rake_original_teardown
          Rake.application = @original_rake
        end

      end
    end

  end

end
