# ImageCollector

Simple tool to download a list of images from a plain text file. Image urls in a given file should be separated by whitespace.


## Usage
### Via CLI
```shell
  gem install image_collector
  image-collector -f tmp/images.txt -d tmp -m 10 -k -r 5 > out.log
```

### Via ruby console
```rb
require 'image_collector'
ImageCollector::Downloader.new(from: 'tmp/images.txt', dest: 'tmp', max_size: '10', keep: true, max_redirects: 5).download
```

## Features

Before actual downloading tool firstly send HEAD request to make sure, that remote link:
* does not lead to too many redirects;
* is really image; 
* actually exists; 
* is smaller then `max_size`.

If you pass the flag `-k` url-based sha-256 digest will be calculated. If there is a image with name equals that digest and with the same extension and its modification time is later than the header `Last-Modified` value, the image will not be overwritten.

## TODO
* FTP support