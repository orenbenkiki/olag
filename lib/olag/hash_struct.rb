# Extend the core Hash class.
class Hash

  # Provide OpenStruct/JavaScript-like implicit <tt>.key</tt> and
  # <tt>.key=</tt> methods.
  def method_missing(method, *arguments)
    method = method.to_s
    key = method.chomp("=")
    return method == key ? self[key] : self[key] = arguments[0]
  end

end
