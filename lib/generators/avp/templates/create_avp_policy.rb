class CreateAvpPolicy < ActiveRecord::Migration[7.1]
  def change
    create_table :avp_policies do |t|
      t.string :name, null: false
      t.string :policy_type, null: false
      t.string :md5
      t.string :policy_id
      t.string :store_id
      t.timestamps
    end
    add_index :avp_policies, [:name, :type], unique: true, name: 'idx_avp_p_name_type'
    add_index :avp_policies, [:name, :id], name: 'idx_avp_p_name_id'
    add_index :avp_policies, [:md5]
  end
end
