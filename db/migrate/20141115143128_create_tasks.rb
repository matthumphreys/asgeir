class CreateTasks < ActiveRecord::Migration
  def change
  	change_column :users, :handle, :string, :limit => 20

  	create_table :tasks do |t|
      t.string :title
      t.integer :priority
      t.string :status
      #t.members
    end
  end
end
