require 'image_collector'
require 'optparse'

module ImageCollector
  class CLI

    def run argv
      options = parse_options(argv)
      ImageCollector::Downloader.new(from: options[:from], dest: options[:dest], max_size: options[:max_size], keep: options[:keep]).download
    end
  
    private
  
    def parse_options argv
      options = {
        from: "",
        dest: "/tmp",
        max_size: 5,
        max_redirects: 5,
        keep: false
      }
      OptionParser.new do |opts|
        opts.banner = "Usage: image-downloader -f path/to/source_list.txt -d path/to/destination [options]"
      
        opts.on("-f", "--from [STRING]", String, "Path to source file") do |v|
          options[:from] = v 
        end
      
        opts.on("-d", "--destination folder STRING", String, "Path to destination folder, default is the current folder") do |v|
          options[:dest] = v 
        end

        opts.on("-m", "--max-size NUMBER", Integer, "Max image size (MB), default 5 MB")  do |v|
          options[:max_size] = v
        end

        opts.on("-k", "--keep", "Do not overwrite already downloaded images") do |v|
          options[:keep] = true 
        end
      
        opts.on("-r", "--max-redirects", "Max allowable redirects number") do |v|
          options[:keep] = v 
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