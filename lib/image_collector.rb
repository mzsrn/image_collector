module ImageCollector
  class Error < StandardError; end
  class NotFound < Error; end
  class TooLarge < Error; end
  class TimeoutError < Error; end
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

end
