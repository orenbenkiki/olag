module Olag

  # Collect a list of errors.
  class Errors < Array

    # The current path we are reporting errors for, if any.
    attr_reader :path

    # The current line number we are reporting errors for, if any.
    attr_reader :line_number

    # Create an empty errors collection.
    def initialize
      @path = nil
      @line_number = nil
    end

    # Associate all errors collected by a block with a specific disk file.
    def in_path(path, &block)
      prev_path, prev_line_number = @path, @line_number
      @path, @line_number = path, nil
      result = block.call(path)
      @path, @line_number = prev_path, prev_line_number
      return result
    end

    # Associate all errors collected by a block with a disk file that is opened
    # and passed to the block.
    def in_file(path, mode = "r", &block)
      return in_path(path) { File.open(path, mode, &block) }
    end

    # Associate all errors collected by a block with a line read from a disk
    # file that is opened and passed to the block.
    def in_file_lines(path, &block)
      in_file(path) do |file|
        @line_number = 0
        file.each_line do |line|
          @line_number += 1
          block.call(line)
        end
      end
    end

    # Set the line number for any errors collected from here on.
    def at_line(line_number)
      @line_number = line_number
    end

    # Add a single error to the collection, with automatic context annotation
    # (current disk file and line). Other methods (push, += etc.) do not
    # automatically add the context annotation.
    def <<(message)
      push(annotate_error_message(message))
    end

  protected

    # Annotate an error message with the context (current file and line).
    def annotate_error_message(message)
      return "#{$0}: #{message}" unless @path
      return "#{$0}: #{message} in file: #{@path}" unless @line_number
      return "#{$0}: #{message} in file: #{@path} at line: #{@line_number}"
    end

  end

end
