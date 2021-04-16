require 'spec_helper'

RSpec.describe ImageCollector::DownloadManager do

  after(:each) { FileUtils.rm_rf(Dir['spec/downloads/*'].reject{|name| name == '.keep'}) }

  subject { described_class.new(arguments).download }
  let(:arguments) { { source: source, dest: dest} }
  let(:response_headers) { { "Content-Type" => content_type, "Content-Length" => content_length } }
  let(:content_type) { "image/png" }
  let(:content_length) { 100 }
  let(:source) { "spec/fixtures/test_urls.txt" } 
  let(:dest) { "spec/downloads" } 

  describe 'If source file does not exist' do
    let(:source) { "spec/fixtures/unexisted_urls.txt" } 

    it 'should raise an error and do not write images' do
      expect{subject}.to change{Dir["spec/downloads/*"].length}.by(0).and raise_error(SystemExit, "Source file does not exist")
    end
  end

  describe 'If destination folder does not exist' do
    let(:dest) { "spec/fixtures/unexisted_urls.txt" } 

    it 'should raise an error and do not write images' do
      expect{subject}.to change{Dir["spec/downloads/*"].length}.by(0).and raise_error(SystemExit, "Destination folder does not exist")
    end
  end

  describe 'If inputs are valid' do

    before do
      stub_request(:head, "http://example.link.one").to_return(status: 200, headers: response_headers)
      stub_request(:head, "http://example.link.two").to_return(status: 200, headers: response_headers)
      stub_request(:head, "http://example.link.three").to_return(status: 200, headers: response_headers)

      stub_request(:get, "http://example.link.one").to_return(status: 200, body: "", headers: response_headers)
      stub_request(:get, "http://example.link.two").to_return(status: 200, body: "", headers: response_headers)
      stub_request(:get, "http://example.link.three").to_return(status: 200, body: "", headers: response_headers)
    end

    it 'should write images' do
      expect{subject}.to change{Dir["spec/downloads/*"].length}.by 3
    end
  end

end
