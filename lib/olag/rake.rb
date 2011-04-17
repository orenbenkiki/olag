require "codnar/rake"
require "olag/change_log"
require "olag/gem_specification"
require "olag/update_version"
require "olag/version"
require "rake/clean"
require "rake/gempackagetask"
require "rake/rdoctask"
require "rake/testtask"
require "rcov/rcovtask"
require "reek/rake/task"
require "roodi"

module Olag

  # Automate Rake task creation for a gem.
  class Rake

    # Define all the Rake tasks.
    def initialize(spec)
      @spec = spec
      @ruby_sources = [ "Rakefile" ] + (@spec.files + @spec.test_files).find_all { |file| file =~ /\.rb$/ }
      task(:default => :all)
      define_all_task
      CLOBBER << "saikuro"
    end

  protected

    # Define a task that does "everything".
    def define_all_task
      define_desc_task("Version, verify, document, package", :all => [ :version, :verify, :doc, :package ])
      define_verify_task
      define_doc_task
      define_commit_task
      # This is a problem. If the version number gets updated, GemPackageTask
      # fails. This is better than if it used the old version number, I
      # suppose, but not as nice as if it just used @spec.version everywhere.
      # The solution for this is to do a dry run before doing the final +rake+
      # +commit+, which is a good idea in general.
      ::Rake::GemPackageTask.new(@spec) { |package| }
    end

    # {{{ Verify gem functionality

    # Define a task to verify everything is OK.
    def define_verify_task
      define_desc_task("Test, coverage, analyze code", :verify => [ :coverage, :analyze ])
      define_desc_class("Test code covarage with RCov", Rcov::RcovTask, "coverage") { |task| Rake.configure_coverage_task(task) }
      define_desc_class("Test code without coverage", ::Rake::TestTask, "test") { |task| Rake.configure_test_task(task) }
      define_analyze_task
    end

    # Configure a task to run all tests and verify 100% coverage. This is
    # cheating a bit, since it will not complain about files that are not
    # reached at all from any of the tests.
    def self.configure_coverage_task(task)
      task.test_files = FileList["test/*.rb"]
      task.libs << "lib" << "test/lib"
      task.rcov_opts << "--failure-threshold" << "100"
    end

    # Configure a task to just run the tests without verifying coverage.
    def self.configure_test_task(task)
      task.test_files = FileList["test/*.rb"]
      task.libs << "lib" << "test/lib"
    end

    # }}}

    # {{{ Analyze the source code

    # Define a task to verify the source code is clean.
    def define_analyze_task
      define_desc_task("Analyze source code", :analyze => [ :reek, :roodi, :flay, :saikuro ])
      define_desc_class("Check for smelly code with Reek", Reek::Rake::Task) { |task| configure_reek_task(task) }
      define_desc_task("Check for smelly code with Roodi", :roodi) { run_roodi_task }
      define_desc_task("Check for duplicated code with Flay", :flay) { run_flay_task }
      define_desc_task("Check for complex code with Saikuro", :saikuro) { run_saikuro_task }
    end

    # Configure a task to ensure there are no code smells using Reek.
    def configure_reek_task(task)
      task.reek_opts << "--quiet"
      task.source_files = @ruby_sources
    end

    # Run Roodi to ensure there are no code smells.
    def run_roodi_task
      runner = Roodi::Core::Runner.new
      runner.config = "roodi.config" if File.exist?("roodi.config")
      @ruby_sources.each { |ruby_source| runner.check_file(ruby_source) }
      (errors = runner.errors).each { |error| puts(error) }
      raise "Roodi found #{errors.size} errors." unless errors.empty?
    end

    # Run Flay to ensure there are no duplicated code fragments.
    def run_flay_task
      dirs = %w(bin lib test/lib).find_all { |dir| File.exist?(dir) }
      result = IO.popen("flay " + dirs.join(' '), "r").read.chomp
      return if result == "Total score (lower is better) = 0\n"
      print(result)
      raise "Flay found code duplication."
    end

    # Run Saikuro to ensure there are no overly complex functions.
    def run_saikuro_task
      dirs = %w(bin lib test).find_all { |dir| File.exist?(dir) }
      system("saikuro -c -t -y 0 -e 10 -o saikuro/ -i #{dirs.join('-i ')} > /dev/null")
      result = File.read("saikuro/index_cyclo.html")
      raise "Saikuro found complicated code." if result.include?("Errors and Warnings")
    end

    # }}}

    # {{{ Generate RDoc documentation

    # Define a task to build all the documentation.
    def define_doc_task
      desc "Generate all documentation"
      task :doc => [ :rdoc, :codnar ]
      ::Rake::RDocTask.new { |task| configure_rdoc_task(task) }
      define_codnar_task
    end

    # Configure a task to build the RDoc documentation.
    def configure_rdoc_task(task)
      task.rdoc_files += @ruby_sources - [ "Rakefile" ] + [ "LICENSE", "README.rdoc" ]
      task.main = "README.rdoc"
      task.rdoc_dir = "rdoc"
      task.options = @spec.rdoc_options
    end

    # }}}

    # {{{ Generate Codnar documentation

    # A set of file Regexp patterns and their matching Codnar configurations.
    # All the gem files are matched agains these patterns, in order, and a
    # Codnar::SplitTask is created for the first matching one. If the matching
    # configuration list is empty, the file is not split. However, the file
    # must match at least one of the patterns. The gem is expected to modify
    # this array, if needed, before creating the Rake object.
    CODNAR_CONFIGURATIONS = [
      [
        # Exclude the ChangeLog and generated codnar.html files from the
        # generated documentation.
        "ChangeLog|codnar\.html",
      ], [
        # Configurations for splitting Ruby files. Using Sunlight makes for
        # fast splitting but slow viewing. Using GVim is the reverse.
        "Rakefile|.*\.rb|bin/.*",
        "classify_source_code:ruby",
        "format_code_sunlight:ruby",
        "classify_shell_comments",
        "format_rdoc_comments",
        "chunk_by_vim_regions",
      ], [
        # Configurations for HTML documentation files.
        ".*\.html",
        "split_html_documentation",
      ], [
        # Configurations for Markdown documentation files.
        ".*\.markdown|.*\.md",
        "split_markdown_documentation",
      ], [
        # Configurations for RDOC documentation files.
        "LICENSE|.*\.rdoc",
        "split_rdoc_documentation",
      ],
    ]

    # Define a task to build the Codnar documentation.
    def define_codnar_task
      Rake.define_split_tasks(@spec.extra_rdoc_files)
      Rake.define_split_tasks(@spec.files)
      Rake.define_split_tasks(@spec.test_files)
      Rake.define_split_tasks(@spec.executables)
      Codnar::Rake::WeaveTask.new("doc/root.html", [ :weave_include, :weave_named_chunk_with_containers ])
    end

    # Define split tasks for a list of files based on CODNAR_CONFIGURATIONS.
    def self.define_split_tasks(files)
      files.each do |file|
        configurations = Rake.split_configurations(file)
        Codnar::Rake::SplitTask.new([ file ], configurations) unless configurations == []
      end
    end

    # Find the Codnar split configurations for a file.
    def self.split_configurations(file)
      CODNAR_CONFIGURATIONS.each do |configurations|
        regexp = configurations[0] = convert_to_regexp(configurations[0])
        return configurations[1..-1] if regexp.match(file)
      end
      abort("No Codnar configuration for file: #{file}")
    end

    # Convert a string configuration pattern to a real Regexp.
    def self.convert_to_regexp(regexp)
      return regexp if Regexp == regexp
      begin
        return Regexp.new("^(#{regexp})$")
      rescue
        abort("Invalid pattern regexp: ^(#{regexp})$ error: #{$!}")
      end
    end

    # }}}

    # {{{ Automate Git commit process

    # Define a task that commit changes to Git.
    def define_commit_task
      define_desc_task("Git commit process", :commit => [ :all, :first_commit, :changelog, :second_commit ])
      define_desc_task("Update version file from Git", :version) { update_version_file }
      define_desc_task("Perform the 1st (main) Git commit", :first_commit) { run_git_first_commit }
      define_desc_task("Perform the 2nd (amend) Git commit", :second_commit) { run_git_second_commit }
      define_desc_task("Update ChangeLog from Git", :changelog) { Olag::ChangeLog.new("ChangeLog") }
    end

    # Update the content of the version file to contain the correct Git-derived
    # build number.
    def update_version_file
      version_file = @spec.version_file
      @spec.version = Olag::Version::update(version_file)
      load(version_file)
    end

    # Run the first Git commit. The user will be given an editor to review the
    # commit and enter a commit message.
    def run_git_first_commit
      raise "Git 1st commit failed" unless system("set +x; git commit")
    end

    # Run the second Git commit. This amends the first commit with the updated
    # ChangeLog.
    def run_git_second_commit
      raise "Git 2nd commit failed" unless system("set +x; EDITOR=true git commit --amend ChangeLog")
    end

    # }}}

    # {{{ Task utilities

    # Define a new task with a description.
    def define_desc_task(description, *parameters)
      desc(description)
      task(*parameters) do
        yield(task) if block_given?
      end
    end

    # Define a new task using some class.
    def define_desc_class(description, klass, *parameters)
      desc(description)
      klass.new(*parameters) do |task|
        yield(task) if block_given?
      end
    end

    # }}}

  end

end
