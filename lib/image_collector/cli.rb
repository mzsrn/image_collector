require 'image_collector/download_manager'
require 'optparse'

module ImageCollector
  class CLI

    def run argv
      options = parse_options(argv)
      ImageCollector::DownloadManager.new(**options).download
    end
  
    private
  
    def parse_options argv
      options = {
        source: "",
        dest: "/tmp",
        concurrently: false,
        max_size: 5,
        max_redirects: 5,
        max_timeout: 5,
        max_retries: 1,
        keep: false,
        sep: ' '
      }
      OptionParser.new do |opts|
        opts.banner = "Usage: image-downloader -f path/to/source_list.txt -d path/to/destination [options]"
      
        opts.on("-s", "--source STRING", String, "Path to source file") do |v|
          options[:source] = v 
        end
      
        opts.on("-d", "--destination STRING", String, "Path to destination folder, default is the current folder") do |v|
          options[:dest] = v 
        end
              
        opts.on("-c", "--concurrently", "Enable multi-thread mode (default: false)") do |v|
          options[:concurrently] = true 
        end

        opts.on("-m", "--max-size NUMBER", Integer, "Maximum allowed image size in MB (default: 5)")  do |v|
          options[:max_size] = v
        end

        opts.on("--max-redirects NUMBER", Integer, "Maximum allowed redirects number (default: 5)")  do |v|
          options[:max_redirects] = v
        end

        opts.on("--max-timeout NUMBER", Integer, "Maximum allowed timeout value in seconds (default: 2)")  do |v|
          options[:max_timeout] = v
        end

        opts.on("--max-retries NUMBER", Integer, "Maximum allowed redirects number (default: 1)")  do |v|
          options[:max_retries] = v
        end

        opts.on("-k", "--keep", "Keep existing output images (default false)") do |v|
          options[:keep] = true 
        end

        opts.on("--sep STRING", String, "separator used in `source` parsing (default: whitespace)") do |v|
          options[:sep] = v
        end
      
        opts.on('-h', '--help', 'Displays Help') do
          puts opts
          exit
        end
      end.parse!(argv)
      options
    end
  end
end