class AddJsonFixtureToApiTests < ActiveRecord::Migration
  def up
    add_column :api_tests, :json_fixture, :text
    remove_column :api_tests, :fixtures_file
  end

  def down
    remove_column :api_tests, :json_fixture
    add_column :api_tests, :fixtures_file, :text
  end
end
