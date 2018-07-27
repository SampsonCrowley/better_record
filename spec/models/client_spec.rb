require 'rails_helper'

RSpec.describe Client, type: :model do
  has_valid_factory(:client)

  describe 'Attributes' do
    # first_name: :text, required
    #  last_name: :text, required
    #      email: :text
    #      phone: :text
    # phone_type: :text
    # created_at: :datetime, required
    # updated_at: :datetime, required

    pending "add some examples to (or delete) #{__FILE__} Attributes"
  end

  describe 'Associations' do
    pending "add some examples to (or delete) #{__FILE__} Attributes"
  end
end
