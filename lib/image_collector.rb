module ImageCollector

  class Error < StandardError; end
  class NotFound < Error; end
  class TooLarge < Error; end
  class InvalidContentType < Error; end

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

  def self.download path
    raise 'File does not exist' unless File.exists?(path)
    # use #each_line since we don't know how large the input file is. 
    File.open(path).each_line(' ') { |line| process(line.strip) } 
  end

  private

  def process line
    raise URI::InvalidURIError, "invalid URI" unless ((line.strip =~ URI::regexp(["http", "https"])) == 0)
    @url = URI(line)
    # Firstly make just HEAD request to make sure that remote image is really image, it exists and it is smaller then 5 MB 
    @head_response = make_head_request
    return if head_response_is_invalid?

    # Then make sure we do not have the same image already downloaded
    return if already_downloaded?

    save
  rescue URI::InvalidURIError => e
    puts "Invalid URI #{e.inspect}" 
  rescue Error => e
    puts "#{e.class}: #{e.message}"
  end


  def make_head_request
    Net::HTTP.start(@url.host, @url.port, use_ssl: use_ssl?) do |http|
      request = Net::HTTP::Head.new(@url)
      http.request(request)
    end
  end

  def head_response_is_invalid?
    response = @head_response
    raise NotFound, "file was not found" if response.code.to_i >= 400
    raise TooLarge, "file is too large, max available size is 5 MB" if response.content_length > (5 * 1024 * 1024)
    raise InvalidContentType, "file extension is not allowed" unless response.content_type.in? ALLOWED_MIME_DICTIONARY.keys
    return false
  end

  def save
    File.open(file_path, 'wb') do |f|
      begin
        Net::HTTP.get_response(@url) do |http|
          # Write in chunks to avoid potential extra memory consumption
          http.read_body{|chunk| f.write chunk }
        end
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
    dir = __dir__ + '/'
    name = Digest::SHA256.hexdigest(@url.to_s)
    extension = '.' + ALLOWED_MIME_DICTIONARY[@head_response.content_type]
    [dir, name, extension].join
  end

  def already_downloaded?
    File.exists?(file_path) && (File.mtime(file_path).to_datetime > @head_response.header["last-modified"])
  end

end
