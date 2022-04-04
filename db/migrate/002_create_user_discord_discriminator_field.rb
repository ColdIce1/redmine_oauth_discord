class CreateUserDiscordDiscriminatorField < ActiveRecord::Migration[5.2]
  def change
    unless ActiveRecord::Base.connection.column_exists?(:users, :discord_discriminator)
      add_column :users, :discord_discriminator, :string
    end
  end
end
