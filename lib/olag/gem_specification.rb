# Monkey-patch within the Gem module.
module Gem

  # Enhanced automated gem specification.
  class Specification

    # The title of the gem for documentation (by default, the capitalized
    # name).
    attr_accessor :title

    # The name of the file containing the gem's version (by default,
    # <tt>lib/_name_/version.rb</tt>).
    attr_accessor :version_file

    alias_method :original_initialize, :initialize

    # Create the gem specification. Requires a block to set up the basic gem
    # information (name, version, author, email, description). In addition, the
    # block may override default properties (e.g. title).
    def initialize(&block)
      original_initialize(&block)
      setup_default_members
      add_development_dependencies
      setup_file_members
      setup_rdoc
    end

    # Set the new data members to their default values, unless they were
    # already set by the gem specification block.
    def setup_default_members
      name = self.name
      @title ||= name.capitalize
      @version_file ||= "lib/#{name}/version.rb"
    end

    # Add dependencies required for developing the gem.
    def add_development_dependencies
      add_dependency("olag") unless self.name == "olag"
      %w(Saikuro codnar fakefs flay rake rcov rdoc reek roodi test-spec).each do |gem|
        add_development_dependency(gem)
      end
    end

    # Initialize the standard gem specification file list members.
    def setup_file_members
      # These should cover all the gem's files, except for the extra rdoc
      # files.
      setup_file_member(:files, "{lib,doc}/**/*")
      self.files << "Rakefile" << "codnar.html"
      setup_file_member(:executables, "bin/*") { |path| path.sub("bin/", "") }
      setup_file_member(:test_files, "test/**/*")
    end

    # Initialize a standard gem specification file list member to the files
    # matching a pattern. If a block is given, it is used to map the file
    # paths. This will not override the file list member if it has already been
    # set by the gem specification block.
    def setup_file_member(member, pattern, &block)
      value = send(member)
      return unless value == []
      value = FileList[pattern].find_all { |path| File.file?(path) }
      value.map!(&block) if block
      send("#{member}=", value)
    end

    # Setup RDOC options in the gem specification.
    def setup_rdoc
      self.extra_rdoc_files = [ "README.rdoc", "LICENSE", "ChangeLog" ]
      self.rdoc_options << "--title" << "#{title} #{version}" \
                        << "--main" << "README.rdoc" \
                        << "--line-numbers" \
                        << "--all" \
                        << "--quiet"
    end

  end

end
