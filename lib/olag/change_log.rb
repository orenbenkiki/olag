module Olag

  # Create ChangeLog files based on the Git revision history.
  class ChangeLog

    # Write a changelog based on the Git log.
    def initialize(path)
      @subjects_by_id = {}
      @sorted_ids = []
      read_log_lines
      File.open(path, "w") do |file|
        @log_file = file
        write_log_file
      end
    end

  protected

    # Read all the log lines from Git's revision history.
    def read_log_lines
      IO.popen("git log --pretty='format:%ci::%an <%ae>::%s'", "r").each_line do |log_line|
        load_log_line(log_line)
      end
    end

    # Load a single Git log line into memory.
    def load_log_line(log_line)
      id, subject = ChangeLog.parse_log_line(log_line)
      @sorted_ids << id
      @subjects_by_id[id] ||= []
      @subjects_by_id[id] << subject
    end

    # Extract the information we need (ChangeLog entry id and subject) from a
    # Git log line.
    def self.parse_log_line(log_line)
      date, author, subject = log_line.chomp.split("::")
      date, time, zone = date.split(" ")
      id = "#{date}\t#{author}"
      return id, subject
    end

    # Write a ChangeLog file based on the read Git log lines.
    def write_log_file
      @sorted_ids.uniq.each do |id|
        write_log_entry(id, @subjects_by_id[id])
      end
    end

    # Write a single ChaneLog entry.
    def write_log_entry(id, subjects)
      @log_file.puts "#{id}\n\n"
      @log_file.puts subjects.map { |subject| "\t* #{subject}" }.join("\n")
      @log_file.puts "\n"
    end

  end

end
