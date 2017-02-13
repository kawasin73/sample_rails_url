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
    scheme "MyString"
    host "MyString"
    port 1
    path "MyText"
    query "MyText"
    fragment "MyText"
    path_component_hash "MyString"
    hash_number 1
  end
end
