# ImageCollector

Simple tool to download a list of images from a plain text file. 

## Usage
### Via CLI
```shell
  gem install image_collector
  image-collector -f tmp/images.txt -d tmp -k -m 1 --max-timeout 1 --sep \; > out.log
```

To get more parameters info please use `image-collector --help`

### Via ruby console
```rb
require 'image_collector'
ImageCollector::Downloader.new(source: 'tmp/images.txt', dest: 'tmp', max_size: '10', , max_redirects: 5, max_retries: 3, keep: true, sep: ' ').download
```

#### Arguments
* `source` - source file location;
* `dest` - destination folder location;
* `max_size` - maximum allowed image size in MB (default: 5);
* `max_redirects` - maximum allowed redirects number (default: 5);
* `max_timeout` - maximum allowed timeout value in seconds (default: 2);
* `max_retries` - maximum allowed redirects number (default: 1);
* `keep` - keep existing output images (default `false`);
* `sep` - separator used in `source` parsing (default: `' '`).

## Features

Before actual downloading tool firstly sends HEAD request to make sure, that remote link:
* actually exists; 
* does not contain too many redirects;
* does not have timeout issues;
* is really image; 
* is smaller then `max_size`;
* responds in `max_timeout`.

If you pass the flag `-k` url-based sha-256 digest will be calculated. If there is a image with name equals that digest and with the same extension and its modification time is later than the header `Last-Modified` value, the image will not be overwritten.

## TODO
* FTP support