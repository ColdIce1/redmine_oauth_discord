class UpdateDiscordUserFields < ActiveRecord::Migration[5.2]
  def change
    # Discord ID aka. snowflake has large numbers. Convert field to 8 byte from 4 byte int
    change_column :users, :auth_source_id, :bigint

    if postgre?
      change_column :users, :discord_id, "bigint USING CAST(discord_id AS bigint)"
    elsif mysql?
      change_column :users, :discord_id, :bigint
    elsif sqlite?
      change_column :users, :discord_id, :integer
    end
  end

  def mysql?
    ActiveRecord::Base.connection.adapter_name =~ /mysql/i
  end

  def postgre?
    ActiveRecord::Base.connection.adapter_name =~ /postgresql/i
  end

  def sqlite?
    ActiveRecord::Base.connection.adapter_name =~ /sqlite/i
  end
end
