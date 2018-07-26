require 'rails_helper'

RSpec.describe TestAudit, type: :model do
  has_valid_factory(:test_audit)

  describe 'Attributes' do
    #  test_text: :text
    #  test_date: :date
    #  test_time: :datetime
    # created_at: :datetime, required
    # updated_at: :datetime, required

    pending "add some examples to (or delete) #{__FILE__} Attributes"
  end

  describe 'Associations' do
    pending "add some examples to (or delete) #{__FILE__} Attributes"
  end
end
