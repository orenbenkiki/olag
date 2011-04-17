# Extend the core String class.
class String

  # Strip away common indentation from the beginning of each line in this
  # String. By default, detects the indentation from the first line. This can
  # be overriden to the exact (String) indentation to strip, or to the (Fixnum)
  # number of spaces the first line is further-indented from the rest of the
  # text.
  def unindent(unindentation = 0)
    unindentation = " " * (indentation.length - unindentation) if Fixnum === unindentation
    return gsub(/^#{unindentation}/, "")
  end

  # Extract the indentation from the beginning of this String.
  def indentation
    return sub(/[^ ].*$/m, "")
  end

end
