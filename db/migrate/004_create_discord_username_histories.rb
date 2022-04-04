class CreateDiscordUsernameHistories < ActiveRecord::Migration[5.2]
  def change
    create_table "discord_username_histories", id: :serial do |t|
      t.integer "user_id", default: 0, null: false
      t.string "username", null: false
      t.string "discriminator", null: false
      t.datetime "created_on", null: false
    end
    add_index :discord_username_histories, :user_id
    add_index :discord_username_histories, :username, unique: false
  end
end
