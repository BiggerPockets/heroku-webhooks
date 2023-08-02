class CreateInvalidUserIds < ActiveRecord::Migration[7.0]
  def change
    create_table :invalid_user_ids do |t|
      t.string :value
      t.integer :aliased_to

      t.timestamps
    end
  end
end
