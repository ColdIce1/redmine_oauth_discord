class CreateDiscordUserFields < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :discord_id, :string
    add_column :users, :discord_avatar_url, :string
  end
end
