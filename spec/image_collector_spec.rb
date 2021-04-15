require 'spec_helper'
require 'image_collector/downloader'
require 'webmock/rspec'

RSpec.describe ImageCollector::Downloader do

  after(:each) { FileUtils.rm_rf(Dir['spec/downloads/*'].reject{|name| name == '.keep'}) }
  subject { described_class.new(*arguments.values) }

  # Inputs
  let(:dest) { 'spec/downloads' }
  let(:max_size) { 1 }
  let(:max_redirects) { 2 }
  let(:keep) { false }
  let(:arguments) { { line: url, idx: 1, dest: dest, max_size: max_size, max_redirects: max_redirects, keep: keep } }

  # Stub Valid Response
  let(:url) { "http://dummy.com/image.jpg" }
  let(:response_headers) { { "Content-Type" => content_type, "Content-Length" => content_length } }
  let(:content_type) { "image/png" }
  let(:content_length) { 2048 }
  let(:head_status) { 200 }
  before { stub_request(:head, url).to_return(status: head_status, body: "", headers: response_headers) }
  
  describe 'should execute successfully and' do
    let(:get_status) { 200 }

    before do
      stub_request(:get, url).to_return(status: get_status, body: body, headers: response_headers)
    end

    let(:body) { "a" * 20 }
    let(:expected_path) { dest + '/' + Digest::SHA256.hexdigest(url) + ".png" }

    it 'save file on disk' do
      expect do
        subject.process
        expect(File.exists? expected_path).to be true
      end.to output(/was saved as/).to_stdout
    end

  end

  describe 'If head response is invalid' do
    before { stub_request(:head, url).to_return(status: head_status, body: "", headers: response_headers) } 

    shared_examples_for "invalid HEAD response" do
      it 'should raise an error and put message to STDOUT' do
        expect{subject.process}.to output(/#{expected_error_message}/).to_stdout
      end
    end

    context 'and file does not exist' do
      let(:content_type) { "i'm not and image" }
      let(:expected_error_message) { "file extension is not allowed" }
      it_behaves_like("invalid HEAD response")
    end

    context 'and returns 4xx status' do
      let(:head_status) { 404 }
      let(:expected_error_message) { "file was not found" }
      it_behaves_like("invalid HEAD response")
    end

    context 'and file is too large' do
      let(:content_length) { 6 * 1024 * 1024 }
      let(:expected_error_message) { "file is too large, max available size is" }
      it_behaves_like("invalid HEAD response")
    end

    context 'and there was too many redirects' do
      let(:head_status) { 302 }
      let(:response_headers) { { "Location" => redirect_url } }

      let(:redirect_url) { "http://redirect.com" }
      let(:redirect_headers) { { "Location" => url } }
      
      let(:expected_error_message) { "too many redirects" }

      before { stub_request(:head, redirect_url).to_return(status: head_status, headers: redirect_headers) } 

      it_behaves_like("invalid HEAD response")
    end

    context 'and there was a socket open error' do
      before { allow_any_instance_of(Net::HTTP).to receive(:start).and_raise(SocketError) }
      let(:expected_error_message) { "failed to open TCP connection" }
      it_behaves_like("invalid HEAD response")
    end
    
    [Net::ReadTimeout, Net::OpenTimeout].each do |error_class|
      context "and there was a #{error_class}" do
        before { allow_any_instance_of(Net::HTTP).to receive(:start).and_raise(error_class) }
        let(:expected_error_message) { "timeout error" }
        it_behaves_like("invalid HEAD response")
      end
    end
  end

end