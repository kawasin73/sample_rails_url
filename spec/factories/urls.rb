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

FactoryGirl.define do
  factory :url do
    scheme 'https'
    host 'test.com'
    port 0
    sequence(:path) { |n| "/test#{n}" }
    query nil
    fragment nil
    path_component_hash { Digest::MD5.hexdigest(path_component) }
    hash_number 0

    transient do
      path_component do
        path_component = path
        path_component += "?#{query}" if query.present?
        path_component += "##{fragment}" if fragment.present?
        path_component
      end
    end
  end
end
