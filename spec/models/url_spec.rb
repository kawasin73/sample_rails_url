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
      it { is_expected.to validate_length_of(:host).is_at_most(256) }
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

  describe '#path_component_hash' do
    let(:path_component) { '/testtest?query=test#fragment_test' }
    subject { Url.parse("http://example.com#{path_component}").path_component_hash }
    it { is_expected.to eq('bd2c137dbb60e8be659b7a4671c97f56') }
  end

  describe '.parse' do
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
        path_component_hash: '2f2f8090205a43d2a4bb16074f658895',
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

    context 'when duplicate hash' do
      let(:scheme) { 'http' }
      let(:host) { 'example.com' }
      let(:path) { '/path' }
      let(:url_string) { "#{scheme}://#{host}#{path}" }
      let(:hash) { Digest::MD5.hexdigest(path) }

      context 'when same hash url is created' do
        before do
          create(:url, scheme: scheme, host: host, path: '/path1', path_component_hash: hash, hash_number: 0)
        end

        it do
          expect(subject.path_component_hash).to eq(hash)
          expect(subject.hash_number).to eq(1)
        end
      end

      context 'when max hash_number 10 was created' do
        before do
          create(:url, scheme: scheme, host: host, path: '/path9', path_component_hash: hash, hash_number: 9)
          create(:url, scheme: scheme, host: host, path: '/path10', path_component_hash: hash, hash_number: 10)
        end

        it do
          expect(subject.path_component_hash).to eq(hash)
          expect(subject.hash_number).to eq(11)
        end
      end

      context 'when url is already created' do
        let(:created_url) { Url.parse(url_string) }
        before do
          created_url
          create(:url, scheme: scheme, host: host, path: '/path9', path_component_hash: hash, hash_number: 9)
        end

        it do
          expect(subject.path_component_hash).to eq(hash)
          expect(subject.hash_number).to eq(created_url.hash_number)
        end
      end

      context 'when url is created and deleted and created part1' do
        let(:max_hash_number) { 9 }
        before do
          url = Url.parse(url_string)
          create(:url, scheme: scheme, host: host, path: '/path9', path_component_hash: hash, hash_number: max_hash_number)
          url.destroy!
        end

        it do
          expect(subject.path_component_hash).to eq(hash)
          expect(subject.hash_number).to eq(max_hash_number + 1)
        end
      end

      context 'when url is created and deleted and created part2' do
        let(:max_hash_number) { 9 }
        before do
          create(:url, scheme: scheme, host: host, path: '/path9', path_component_hash: hash, hash_number: max_hash_number)
          url = Url.parse(url_string)
          url.destroy!
        end

        it do
          expect(subject.path_component_hash).to eq(hash)
          expect(subject.hash_number).to eq(max_hash_number + 1)
        end
      end
    end
  end

  describe 'uniqueness of id' do
    let(:url_string) { 'http://test.com/test?test=test#test' }
    subject { Url.parse(url_string) }
    it { is_expected.to eq(Url.parse(url_string)) }
  end

  describe '#find_or_create' do
    let(:url) { build(:url) }
    subject { url.find_or_create(max_retry: max_retry) }
    let(:max_retry) { 3 }
    it 'should retry 3 times' do
      expect(url).to receive(:try_to_save).exactly(max_retry + 1).times.and_raise(ActiveRecord::RecordNotUnique)
      expect { subject }.to raise_error(ActiveRecord::RecordNotUnique)
    end
  end

  describe '#same_hash_urls' do
    let(:url) { create(:url, scheme: scheme, host: host, path: path, path_component_hash: path_component_hash, hash_number: hash_number) }
    let(:scheme) { 'http' }
    let(:host) { 'example.com' }
    let(:path) { '/path' }
    let(:path_component_hash) { Digest::MD5.hexdigest(path) }
    let(:hash_number) { 0 }

    subject { url.same_hash_urls }

    let!(:url2) { create(:url, scheme: scheme, host: host, path: path, path_component_hash: path_component_hash, hash_number: hash_number + 1) }
    let!(:url3) { create(:url, scheme: scheme, host: host, path: path, path_component_hash: path_component_hash, hash_number: hash_number + 3) }

    let!(:dummy1) { create(:url, scheme: scheme, host: host, path: path, path_component_hash: invalid_hash, hash_number: hash_number) }
    let!(:dummy2) { create(:url, scheme: invalid_scheme, host: host, path: path, path_component_hash: path_component_hash, hash_number: hash_number) }
    let!(:dummy3) { create(:url, scheme: scheme, host: invalid_host, path: path, path_component_hash: path_component_hash, hash_number: hash_number) }
    let(:invalid_scheme) { 'https' }
    let(:invalid_host) { 'invalid.com' }
    let(:invalid_hash) { 'a' * 32 }

    it do
      expect(subject.count).to eq(3)
      [url, url2, url3].each do |target|
        expect(subject).to include(target)
      end
      [dummy1, dummy2, dummy3].each do |target|
        expect(subject).not_to include(target)
      end
    end
  end

  describe '#try_to_save' do
    let(:url) { build(:url, scheme: scheme, host: host, path: path, path_component_hash: path_component_hash, hash_number: hash_number) }
    let(:scheme) { 'http' }
    let(:host) { 'example.com' }
    let(:path) { '/path' }
    let(:path_component_hash) { Digest::MD5.hexdigest(path) }
    let(:hash_number) { 0 }

    subject { url.send(:try_to_save) }

    let(:same_hash_urls) { [] }

    before do
      allow(url).to receive(:same_hash_urls).and_return(same_hash_urls)
    end

    context 'when same_hash_urls is empty' do
      let(:same_hash_urls) { [] }
      it do
        is_expected.to eq(url)
        expect(subject.hash_number).to eq(0)
        expect(subject.persisted?).to be_truthy
      end

      context 'and hash_number unexpectedly is not 0' do
        let(:hash_number) { 10 }
        it do
          is_expected.to eq(url)
          expect(subject.hash_number).to eq(0)
          expect(subject.persisted?).to be_truthy
        end
      end
    end

    context 'when same_hash_urls does not includes target url' do
      let(:dummy1) { create(:url, scheme: scheme, host: host, path: '/dummy1', path_component_hash: path_component_hash, hash_number: max_hash_number - 1) }
      let(:dummy2) { create(:url, scheme: scheme, host: host, path: '/dummy2', path_component_hash: path_component_hash, hash_number: max_hash_number - 2) }
      let(:max_hash_url) { create(:url, scheme: scheme, host: host, path: '/dummy3', path_component_hash: path_component_hash, hash_number: max_hash_number) }
      let(:max_hash_number) { 10 }

      let(:same_hash_urls) { [dummy1, max_hash_url, dummy2] }
      it do
        is_expected.to eq(url)
        expect(subject.hash_number).to eq(max_hash_number + 1)
        expect(subject.persisted?).to be_truthy
      end

      context 'and max_hash_url is deleted while try to save' do
        before do
          Url.find(max_hash_url.id).destroy!
        end
        it 'is expected to re-save deleted url' do
          expect { max_hash_url.reload }.to raise_error(ActiveRecord::RecordNotFound)
          is_expected.to eq(url)
          expect(subject.hash_number).to eq(max_hash_number + 1)
          expect(subject.persisted?).to be_truthy
          expect(max_hash_url.reload.persisted?).to be_truthy
        end

        context 'and another url is saved' do
          before do
            create(:url, scheme: scheme, host: host, path: '/dummy4', path_component_hash: path_component_hash, hash_number: max_hash_number)
          end
          it { expect { subject }.to raise_error(ActiveRecord::RecordNotUnique) }
        end
      end
    end

    context 'when same_hash_urls includes target url' do
      let(:created_url) { create(:url, scheme: scheme, host: host, path: path, path_component_hash: path_component_hash, hash_number: hash_number) }
      let(:same_hash_urls) { [created_url] }
      it do
        is_expected.to eq(created_url)
        expect(url.persisted?).to be_falsey
      end

      context 'and not target url' do
        let(:dummy) { create(:url, scheme: scheme, host: host, path: '/dummy', path_component_hash: path_component_hash, hash_number: hash_number + 1) }
        let(:same_hash_urls) { [created_url, dummy] }

        it do
          is_expected.to eq(created_url)
          expect(url.persisted?).to be_falsey
        end
      end
    end

    context 'when same_hash_urls includes target url but not unique' do
      let(:created_url) { create(:url, scheme: scheme, host: host, path: path, path_component_hash: path_component_hash, hash_number: hash_number) }
      let(:duplicated_url) { create(:url, scheme: scheme, host: host, path: path, path_component_hash: path_component_hash, hash_number: hash_number + 1) }
      let(:same_hash_urls) { [created_url, duplicated_url] }
      it { expect { subject }.to raise_error("not_unique_urls! url: #{url.to_s}, ids: #{same_hash_urls.map(&:id)}") }
    end
  end
end
