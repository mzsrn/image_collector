module ImageCollector
  class DownloadManager

    def initialize source:, dest:, max_size: 5, max_redirects: 5, max_timeout: 2, max_retries: 1, keep: false, sep: " ", concurrently: false
      abort 'Source file does not exist' unless File.exists?(source)
      abort 'Destination folder does not exist' unless File.directory?(dest)
      @source, @sep, @concurrently = source, sep, concurrently
      @args = [dest, max_size, max_redirects, max_timeout, keep, max_retries]
    end

    def download
      if @concurrently
        count = 5
        queue, threads = start_workers count
        file_iterator(@source, @sep).each do |line, idx|
          queue.push([line, idx])
        end
        count.times { queue.push :terminate }
        threads.each(&:join)
      else
        file_iterator(@source, @sep).each do |line, idx|
          ImageCollector::Downloader.new(line, idx, *@args).process
        end
      end
    end

    private

    def file_iterator source, sep
      Enumerator.new do |y|
        idx = 0
        File.open(source) do |f|
          f.each_line(sep) do |line|
            idx += 1
            unless is_valid_url?(line.strip)
              $stdout.puts "Error: item ##{idx} - '#{line}' is not valid URL"
              next 
            end 
            y << [line.strip, idx]
          end
          f.close
        end
      end
    end

    def start_workers count
      queue = SizedQueue.new(100)
      threads = count.times.map do
        Thread.new(queue) do |queue|
          while pair = queue.pop
            break if pair == :terminate
            ImageCollector::Downloader.new(*pair, *@args).process
          end
        end
      end
      [queue, threads]
    end

    def is_valid_url? line
      uri = URI.parse(line)
      %w(http https).include?(uri.scheme) && !uri.host.nil?
    rescue URI::InvalidURIError
      false
    end

  end
end