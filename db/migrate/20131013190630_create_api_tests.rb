class CreateApiTests < ActiveRecord::Migration
  def up
    create_table :api_tests do|t|
      t.string :token
      t.string :base_url
      t.text   :fixtures_file
    end
  end

  def down
    drop_table :api_tests
  end
end
