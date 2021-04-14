require 'net/http'
require 'date'

module ImageCollector

  class Error < StandardError; end
  class NotFound < Error; end
  class TooLarge < Error; end
  class InvalidContentType < Error; end

  class Downloader

    ALLOWED_MIME_DICTIONARY = {
      "image/gif" => "gif",
      "image/bmp" => "bpm",
      "image/vnd.microsoft.icon" => "ico",
      "image/jpeg" => "jpeg",
      "image/png" => "png",
      "image/svg+xml" => "svg",
      "image/tiff" => "tiff",
      "image/webm" => "webm"
    }.freeze

    def initialize from:, dest:, max_size: 5, max_redirects: 5, keep: false
      abort 'Source file does not exist' unless File.exists?(from)
      abort 'Destination folder does not exist' unless File.directory?(dest)
      @from, @dest, @max_size, @max_redirects, @keep = from, dest, max_size, max_redirects, keep
    end
    
    def download
      # use #each_line since we don't know how large the input file is. 
      idx = 0
      File.open(@from).each_line(' ') do |line| 
        idx += 1
        if ((line.strip =~ URI::regexp(["http", "https"])) != 0)
          return $stdout.puts "Error: item ##{idx} - '#{line}' is not valid URI"
        end
        process(line.strip, idx) 
      end
    end

    private

    def process line, idx
      @url = URI(line)

      # Firstly make just HEAD request to make sure that remote link 
      # * does not contain too many redirects;
      # * is really image; 
      # * actually exists; 
      # * is smaller then max_size.
      @redirects_count = 0
      @head_response = make_head_request
      return if head_response_is_invalid?

      # Then make sure we do not have the same image already downloaded
      return $stdout.puts "Info: item ##{idx} - '#{line}' is already saved as #{file_path}" if (@keep && already_downloaded?) 

      save(idx)
    rescue Error => e
      $stdout.puts "Error: item ##{idx} - '#{line}' #{e.message}"
    end


    def make_head_request
      Net::HTTP.start(@url.host, @url.port, use_ssl: use_ssl?) do |http|
        request = Net::HTTP::Head.new(@url)
        response = http.request(request)
        if response.code.start_with? "3"
          @redirects_count += 1
          prevent_too_many_redirects(response) 
        end
        response
      end
    end

    def prevent_too_many_redirects response
      @url = URI(response.header['location'])
      if @redirects_count < @max_redirects
        make_head_request
      else
        raise NotFound, "too many redirects"
      end
    end

    def head_response_is_invalid?
      response = @head_response
      raise NotFound, "file was not found" if (response.code.start_with?("4") || (response.content_length.to_i == 0))
      raise TooLarge, "file is too large, max available size is #{@max_size} MB" if response.content_length > (@max_size * 1024 * 1024)
      raise InvalidContentType, "file extension is not allowed" unless ALLOWED_MIME_DICTIONARY.keys.include? response.content_type
      return false
    end

    def save(idx)
      File.open(file_path, 'wb') do |f|
        begin
          Net::HTTP.get_response(@url) do |http|
            # Write in chunks to avoid potential extra memory consumption
            http.read_body{|chunk| f.write chunk }
          end
          $stdout.puts "Success: item ##{idx} - '#{@url.to_s}' was saved as #{file_path}" 
        rescue StandardError => e
          FileUtils.rm(f)
          raise e
        end
      end
    end

    def use_ssl?
      @url.is_a? URI::HTTPS
    end

    def file_path
      dir = @dest + '/'
      name = Digest::SHA256.hexdigest(@url.to_s)
      extension = '.' + ALLOWED_MIME_DICTIONARY[@head_response.content_type]
      [dir, name, extension].join
    end

    def already_downloaded?
      File.exists?(file_path) && (File.mtime(file_path).to_datetime > DateTime.parse(@head_response.header["last-modified"]))
    end
  end

end
