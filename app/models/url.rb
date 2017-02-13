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

class Url < ApplicationRecord
  validates :scheme, presence: true
  validates :host, presence: true, length: { maximum: 256 }
  validates :port, presence: true
  validates :path, presence: true
  validates :path_component_hash, presence: true, length: { is: 32 }
  validates :hash_number, presence: true

  validates :scheme, inclusion: { in: %w(http https) }
  validates :path, format: { with: /\A\/.*/ }

  # need no uniqueness validation
  # validates_uniqueness_of :hash_number, scope: [:scheme, :host, :port, :path_component_hash]

  validate :force_immutable

  def to_s
    # "#{scheme}://#{host}#{port > 0 ? ":#{port}" : ''}#{path_component}"
    Addressable::URI.new(scheme: scheme, host: host, port: port, path: path, query: query, fragment: fragment).to_s
  end

  def self.parse(url_string)
    uri = Addressable::URI.parse(url_string.to_s)
    return nil if uri.nil?
    uri.normalize!
    url = Url.new(scheme: uri.scheme.to_s.downcase, host: uri.host.to_s.downcase, port: uri.port || 0, path: uri.path, query: uri.query, fragment: uri.fragment) do |url|
      url.set_hash
    end
    url.find_or_create
  rescue Addressable::URI::InvalidURIError
    nil
  end

  def find_or_create(max_retry: 3)
    try_to_save
  rescue ActiveRecord::RecordInvalid
    nil
  rescue ActiveRecord::RecordNotUnique
    if max_retry > 0
      max_retry -= 1
      retry
    else
      raise
    end
  end

  def set_hash
    self.path_component_hash = Digest::MD5.hexdigest(path_component)
  end

  def path_component
    if @path_component.nil?
      @path_component = path
      @path_component += "?#{query}" if query.present?
      @path_component += "##{fragment}" if fragment.present?
      @path_component
    else
      @path_component
    end
  end

  private

  def try_to_save
    urls = Url.where(scheme: scheme, host: host, port: port, path_component_hash: path_component_hash).to_a
    if urls.empty?
      self.save!
      self
    else
      found_urls = urls.select { |url| url.path_component == self.path_component }
      if found_urls.empty?
        begin
          self.hash_number = urls.map(&:hash_number).max + 1
          self.save!
          self
        rescue ActiveRecord::RecordNotUnique
          self.hash_number = 0
          raise
        end
      elsif found_urls.count == 1
        found_urls.first
      else
        raise "not_unique_urls! url: #{self.to_s}, ids: #{found_urls.map(&:id)}"
      end
    end
  end

  # URL: http://swaac.tamouse.org/rails/2015/08/13/rails-immutable-records-and-attributes/
  def force_immutable
    if self.changed? && self.persisted?
      errors.add(:base, :immutable)
      # Optional: restore the original record
      self.reload
    end
  end
end
