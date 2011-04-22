module Olag

  module Version

    # Update the file containing the gem's version. The file is expected to
    # contain a line in the format: <tt>VERSION =
    # "_major_._minor_._commits_"</tt>. The third number is updated according
    # to the number of Git commits. This works well as long as we are working
    # in the master branch.
    def self.update(path)
      current_file_contents, current_version, correct_version = current_status(path)
      if current_version != correct_version
        correct_file_contents = current_file_contents.sub(current_version, correct_version)
        File.open(path, "w") { |file| file.write(correct_file_contents) }
      end
      return correct_version
    end

  protected

    # Return the current version file contents, the current version, and the
    # correct version.
    def self.current_status(path)
      prefix, current_suffix = extract_version(path, current_file_contents = File.read(path))
      correct_suffix = count_git_commits.to_s
      current_version = prefix + current_suffix
      correct_version = prefix + correct_suffix
      return current_file_contents, current_version, correct_version
    end

    # Extract the version number from the contents of the version file. This is
    # an array of two strings - the prefix containing the major and minor
    # numbers, and the suffix containing the commits number.
    def self.extract_version(path, file_contents)
      abort("#{path}: Does not contain a valid VERSION line.") unless file_contents =~ /VERSION\s+=\s+["'](\d+\.\d+\.)(\d+)["']/
      return [ $1, $2 ]
    end

    # Return the total number of Git commits that apply to the current state of
    # the working directory. This means we add one to the actual number of
    # commits if there are uncommitted changes; this way the version number
    # does not change after doing a commit - it only changes after we make
    # changes following a commit.
    def self.count_git_commits
      git_commits = IO.popen("git rev-list --all | wc -l").read.chomp.to_i
      git_status = IO.popen("git status").read
      git_commits += 1 unless git_status.include?("working directory clean")
      return git_commits
    end

  end

end
