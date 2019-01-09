require 'rails_helper'

module BetterRecord
  RSpec.describe AttachmentValidation, type: :model do
    describe 'Attributes' do
      #          name: :text, required
      # attachment_id: :integer, required
      #           ran: :boolean, required

      required_column(:attachment_validation, :name)
      boolean_column(:attachment_validation, :ran, keep_boolean_strictness: false)
    end

  end
end
