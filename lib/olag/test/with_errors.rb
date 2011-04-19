module Test

  # Mix-in for tests that collect Errors.
  module WithErrors

    # Aliasing methods needs to be deferred to when the module is included
    # and be executed in the context of the class.
    def self.included(base)
      base.class_eval do

        alias_method :errors_original_setup, :setup

        # Automatically create an fresh +@errors+ data member for each test.
        def setup
          errors_original_setup
          @errors = Olag::Errors.new
        end

      end
    end

  end

end
