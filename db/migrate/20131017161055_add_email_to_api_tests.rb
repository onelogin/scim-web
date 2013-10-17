class AddEmailToApiTests < ActiveRecord::Migration
  def up
    add_column :api_tests, :email, :string
  end

  def down
    drop_column :api_tests, :email
  end
end
