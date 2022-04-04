class DiscordUsernameHistory < ActiveRecord::Base
  unloadable
  belongs_to :user
  validates :user_id, presence: true
end
