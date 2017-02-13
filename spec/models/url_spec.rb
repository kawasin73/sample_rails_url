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
  pending "add some examples to (or delete) #{__FILE__}"
end
