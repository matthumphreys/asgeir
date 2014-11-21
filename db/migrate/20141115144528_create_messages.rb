class CreateMessages < ActiveRecord::Migration
  def change
  	change_column :tasks, :title, :string, :null => false
  	change_column :tasks, :status, :string, :limit => 6
  	change_column :tasks, :priority, :integer, :null => false

  	create_table :messages do |t|
  		t.text :msg, null: false
  		t.integer :from_user, null: false
  		t.integer :task_id, null: false
  		t.timestamps
  	end
  	add_index :messages, :from_user
  	add_index :messages, :task_Id
  end
end
