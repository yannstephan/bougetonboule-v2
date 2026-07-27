class ConversationRead < ApplicationRecord
  belongs_to :membership
  belongs_to :conversation
end
