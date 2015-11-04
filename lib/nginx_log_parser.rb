require 'nginx_log_parser/version'

class NginxLogParser
  attr_accessor :format
  attr_accessor :file
  attr_accessor :live

  DEFAULT_FORMAT = "$remote_addr - $remote_user [$time_local] \"$request\" $status $body_bytes_sent \"$http_referer\" \"$http_user_agent\""

  def initialize(file = nil, live: false, format: nil)
    self.file = file
    self.live = live
    self.format = format || DEFAULT_FORMAT

    if file =~ /\.gz$/ and live
      raise StandardError.new "Cannot live stream a .gz file"
    end
  end

  def each_entry
    begin
      f = File.open(file)

      if live
        f.seek(0, IO::SEEK_END)
        while true do
          sleep 0.1 while f.eof?
          yield parse_line(f.gets)
        end
      else
        f.each_line do |line|
          yield parse_line(line)
        end
      end

    ensure
      f.close if f
    end
  end

  def parse_line(line)
    re = format_regex

    pieces = line.match(/#{re}/i)
    matches = Hash[pieces.names.map(&:to_sym).zip(pieces.captures)]
    matches[:status] = matches[:status].to_i if matches[:status]
    matches[:body_bytes_sent] = matches[:body_bytes_sent].to_i if matches[:body_bytes_sent]

    matches
  end

  def format=(new_format)
    @format = new_format

    # Force regex generation
    @fmt = nil
  end

private
  PIECES = {
    remote_addr: "\\d+\\.\\d+\\.\\d+\\.\\d+",
    remote_user: "[a-z_-]+",
    time_local: "\\d{2}/[a-zA-Z]{3}/\\d{4}:\\d{2}:\\d{2}:\\d{2} [+-]\\d{4}",
    request: ".+",
    status: "\\d+",
    body_bytes_sent: "\\d+",
    http_referer: ".+",
    http_user_agent: ".+",
    connection_requests: "\\d+",
    connection: "\\d+",
    msec: "\\d+(?:\\.\\d+)?",
    pipe: "[\\.p]",
    request_length: "\\d+",
    request_time: "\\d+(?:\\.\\d+)?",
    time_iso8601: "\\d{4}-?\\d{2}-?\\d{2}T\\d{2}:?\\d{2}:?\\d{2}(?:[+-]\\d{2}:\\d{2}|[A-Z]{1,5})"
  }

  def format_regex
    @fmt ||= begin
      fmt = format.dup

      # Escape reserved regex symbols
      # Notice that we do not escape the $ symbol
      escapes = %w( ( ) + ? * . \\ . | ^ ) + [ '[', ']' ]
      escapes.each do |char|
        fmt.gsub!(char, "\\\\#{char}")
      end

      puts fmt

      # Replace $vars with regexes
      PIECES.each do |find, replace|
        fmt.gsub!("$#{find}", "(?<#{find}>#{replace})")
      end

      fmt.gsub!(/ /, "\\s+")
      fmt
    end
  end
end
