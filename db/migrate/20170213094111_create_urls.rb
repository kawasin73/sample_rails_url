class CreateUrls < ActiveRecord::Migration[5.0]
  def change
    create_table :urls do |t|
      t.string :scheme, null: false
      t.string :host, null: false
      t.integer :port, null: false, default: 0
      t.text :path, null: false
      t.text :query, null: true
      t.text :fragment, null: true
      t.string :path_component_hash, null: false, limit: 32
      t.integer :hash_number, null: false, default: 0

      t.index [:host, :scheme, :port, :path_component_hash, :hash_number], unique: true, name: 'url_unique_index'
    end
  end
end
