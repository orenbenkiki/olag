$LOAD_PATH.unshift(File.dirname(__FILE__) + "/lib")

require "olag/rake"

# {{{ Gem specification

spec = Olag::GemSpecification.new do |spec|
  spec.name = "olag"
  spec.version = Olag.version
  spec.author = "Oren Ben-Kiki"
  spec.email = "rubygems-oren@ben-kiki.org"
  spec.homepage = "http://olag.rubygems.org"
  spec.summary = "Olag - Oren's Library/Application Gem framework"
  spec.description = (<<-EOF).gsub(/^\s+/, "").chomp.gsub("\n", " ")
    Olag is Oren's set of utilities for creating a well-behaved gem. This is
    very opinionated software; it eliminates a lot of the boilerplate, at the
    cost of making many decisions which may not be suitable for everyone
    (directory structure, code verification, codnar for documentation, etc.).
  EOF
end

# }}}

Olag::Rake.new(spec)
