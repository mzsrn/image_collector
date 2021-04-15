require 'net/http'
require 'fileutils'
require 'date'
require 'image_collector'

module ImageCollector
  class Downloader

    attr_accessor :redirects_count

    def initialize line, idx, dest, max_size=5, max_redirects=5, max_timeout=2, keep=false, max_retries=1
      @line = line
      @idx = idx
      @dest = dest
      @max_size = max_size
      @max_redirects = max_redirects
      @max_timeout = max_timeout
      @keep = keep
      @max_retries = max_retries
    end

    def process 
      self.url = URI(line)

      self.redirects_count = 0
      self.head_response = make_head_request

      # Firstly make just HEAD request to make sure that remote link 
      # * actually exists; 
      # * does not contain too many redirects;
      # * is really image; 
      # * is smaller then max_size;
      # * responds in timeout.
      return if head_response_is_invalid?

      # Then make sure we do not have the same image already downloaded
      return $stdout.puts "Info: item ##{idx} - '#{line}' is already saved as #{file_path}" if (keep && already_downloaded?) 

      save(idx)
    rescue ImageCollector::Error => e
      $stdout.puts "Error: item ##{idx} - '#{line}' #{e.message}"
    end

    private

    attr_accessor :url, :head_response, :max_redirects
    attr_reader :max_retries, :max_timeout, :line, :idx, :line, :keep, :max_size

    def make_head_request
      options = {
        use_ssl: use_ssl?,
        max_retries: max_retries, 
        read_timeout: max_timeout, 
        open_timeout: max_timeout
      }
      Net::HTTP.start(url.host, url.port, **options) do |http|
        request = Net::HTTP::Head.new(url)
        response = http.request(request)
        if response.code.start_with? "3"
          self.redirects_count += 1
          prevent_too_many_redirects(response) 
        end
        response
      end
    rescue Net::ReadTimeout, Net::OpenTimeout
      raise ImageCollector::TimeoutError, "timeout error"
    rescue SocketError, Errno::ECONNREFUSED
      raise ImageCollector::Error, "failed to open TCP connection"
    end

    def prevent_too_many_redirects response
      url = URI(response.header['location'])
      if redirects_count < max_redirects
        make_head_request
      else
        raise ImageCollector::NotFound, "too many redirects"
      end
    end

    def head_response_is_invalid?
      response = head_response
      raise NotFound, "file was not found" if (response.code.start_with?("4") || (response.content_length.to_i == 0))
      raise TooLarge, "file is too large, max available size is #{max_size} MB" if response.content_length > (max_size * 1024 * 1024)
      raise InvalidContentType, "file extension is not allowed" unless ImageCollector::ALLOWED_MIME_DICTIONARY.keys.include? response.content_type
      return false
    end

    def save(idx)
      File.open(file_path, 'wb') do |f|
        begin
          Net::HTTP.get_response(url) do |http|
            # Write in chunks to avoid potential extra memory consumption
            http.read_body{|chunk| f.write chunk }
          end
          $stdout.puts "Success: item ##{idx} - '#{url.to_s}' was saved as #{file_path}" 
        rescue Exception => e
          FileUtils.rm(f)
          raise e
        end
      end
    end

    def use_ssl?
      url.is_a? URI::HTTPS
    end

    def file_path
      dir = @dest + '/'
      name = Digest::SHA256.hexdigest(url.to_s)
      extension = '.' + ImageCollector::ALLOWED_MIME_DICTIONARY[head_response.content_type]
      [dir, name, extension].join
    end

    def already_downloaded?
      File.exists?(file_path) && (File.mtime(file_path).to_datetime > DateTime.parse(head_response.header["last-modified"]))
    end

  end
end