# == Schema Information
#
# Table name: urls
#
#  id                  :integer          not null, primary key
#  scheme              :string           not null
#  host                :string           not null
#  port                :integer          default("0"), not null
#  path                :text             not null
#  query               :text
#  fragment            :text
#  path_component_hash :string(32)       not null
#  hash_number         :integer          default("0"), not null
#
# Indexes
#
#  url_unique_index  (host,scheme,port,path_component_hash,hash_number) UNIQUE
#

require 'rails_helper'

RSpec.describe Url, type: :model do
  let(:url) { build(:url) }

  subject { url }

  it { is_expected.to be_valid }

  it { is_expected.to respond_to(:scheme) }
  it { is_expected.to respond_to(:host) }
  it { is_expected.to respond_to(:path) }
  it { is_expected.to respond_to(:query) }
  it { is_expected.to respond_to(:fragment) }
  it { is_expected.to respond_to(:path_component_hash) }
  it { is_expected.to respond_to(:path_component) }
  it { is_expected.to respond_to(:hash_number) }
  it { is_expected.to respond_to(:to_s) }

  describe 'Validation' do
    describe '#scheme' do
      it { is_expected.to validate_presence_of(:scheme) }
    end
    describe '#host' do
      it { is_expected.to validate_presence_of(:host) }
    end
    describe '#port' do
      it { is_expected.to validate_presence_of(:port) }
    end
    describe '#path' do
      it { is_expected.to validate_presence_of(:path) }
    end
    describe '#path_component_hash' do
      it { is_expected.to validate_presence_of(:path_component_hash) }
      it { is_expected.to validate_length_of(:path_component_hash).is_equal_to(32) }
    end
    describe '#hash_number' do
      it { is_expected.to validate_presence_of(:hash_number) }
    end
  end

  describe '#to_s' do
    let(:scheme) { 'http' }
    let(:host) { 'example.com' }
    let(:port) { 3000 }
    let(:path) { '/test' }
    let(:query) { 'query=query' }
    let(:fragment) { 'fragment' }

    let(:url) { build(:url, scheme: scheme, host: host, port: port, path: path, query: query, fragment: fragment) }

    subject { url.to_s }

    it { is_expected.to eq("#{scheme}://#{host}:#{port}#{path}?#{query}##{fragment}") }

    context 'when port is 0' do
      let(:port) { 0 }
      it { is_expected.to eq("#{scheme}://#{host}#{path}?#{query}##{fragment}") }
    end

    context 'when query is nil' do
      let(:query) { nil }
      it { is_expected.to eq("#{scheme}://#{host}:#{port}#{path}##{fragment}") }
    end

    context 'when fragment is nil' do
      let(:fragment) { nil }
      it { is_expected.to eq("#{scheme}://#{host}:#{port}#{path}?#{query}") }
    end
  end

  describe '#path_component' do
    let(:path_component) { '/testtest?query=test#fragment_test' }
    subject { Url.parse("http://example.com#{path_component}").path_component }
    it { is_expected.to eq(path_component) }
  end

  describe 'Url.parse' do
    let(:url_string) { 'http://example.com:3000/test?query=query#fragment' }
    subject { Url.parse(url_string) }

    it do
      {
        scheme: 'http',
        host: 'example.com',
        port: 3000,
        path: '/test',
        query: 'query=query',
        fragment: 'fragment',
      }.each do |k, v|
        expect(subject.send(k)).to eq(v)
      end
    end

    [
      { context: 'when scheme have LARGE STYLE', string: 'hTtps://example.com/hoge',
        scheme: 'https', host: 'example.com', port: 0, path: '/hoge', query: nil, fragment: nil },
      { context: 'when host have LARGE STYLE', string: 'https://EXAMPLE.com/hoge',
        scheme: 'https', host: 'example.com', port: 0, path: '/hoge', query: nil, fragment: nil },
      { context: 'when path is empty', string: 'https://hoge.hoge',
        scheme: 'https', host: 'hoge.hoge', port: 0, path: '/', query: nil, fragment: nil },
      { context: 'when path is root', string: 'https://hoge.hoge/',
        scheme: 'https', host: 'hoge.hoge', port: 0, path: '/', query: nil, fragment: nil },
      { context: 'when path have LARGE STYLE', string: 'https://example.com/HOGEhoge',
        scheme: 'https', host: 'example.com', port: 0, path: '/HOGEhoge', query: nil, fragment: nil },
      { context: 'when path have last /', string: 'https://example.com/hoge/',
        scheme: 'https', host: 'example.com', port: 0, path: '/hoge/', query: nil, fragment: nil },
    ].each do |params|
      context "#{params[:context]} -> #{params[:string]}" do
        let(:url_string) { params[:string] }
        it do
          { scheme: params[:scheme],
            host: params[:host],
            port: params[:port],
            path: params[:path],
            query: params[:query],
            fragment: params[:fragment] }.each do |k, v|
            expect(subject.send(k)).to eq(v)
          end
        end
      end
    end

    [
      '',
      nil,
      'ftp://example.com/hoge',
      '//hoge.hoge',
      'abcde',
      'http://:3000/hoge',
    ].each do |string|
      context "when url_string is #{string}" do
        let(:url_string) { string }
        it { is_expected.to be_nil }
      end
    end
  end

  describe 'uniqueness of id' do
    let(:url_string) { 'http://test.com/test?test=test#test' }
    subject { Url.parse(url_string) }
    it { is_expected.to eq(Url.parse(url_string)) }
  end

  describe 'when duplicate hash' do
    let(:scheme) { 'http' }
    let(:host) { 'example.com' }
    let(:path) { '/path' }
    let(:url_string) { "#{scheme}://#{host}#{path}" }
    let(:path_component_hash) { Digest::MD5.hexdigest(path) }

    before do
      create(:url, scheme: scheme, host: host, path: '/path1', path_component_hash: path_component_hash, hash_number: 0)
    end

    it do
      url = Url.parse(url_string)
      expect(url.path_component_hash).to eq(path_component_hash)
      expect(url.hash_number).to eq(1)
    end

    context 'when dummy count is 2' do
      before do
        create(:url, scheme: scheme, host: host, path: '/path2', path_component_hash: path_component_hash, hash_number: 1)
      end

      it do
        url = Url.parse(url_string)
        expect(url.path_component_hash).to eq(path_component_hash)
        expect(url.hash_number).to eq(2)
      end
    end

    context 'when hash_number 10 was created' do
      before do
        create(:url, scheme: scheme, host: host, path: '/path10', path_component_hash: path_component_hash, hash_number: 10)
      end

      it do
        url = Url.parse(url_string)
        expect(url.path_component_hash).to eq(path_component_hash)
        expect(url.hash_number).to eq(11)
      end
    end
  end
end
