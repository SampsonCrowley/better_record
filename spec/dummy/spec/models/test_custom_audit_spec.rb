require 'rails_helper'

RSpec.describe TestCustomAudit, type: :model do
  has_valid_factory(:test_custom_audit)

  describe 'Attributes' do
    #           test_text: :text
    #           test_date: :date
    #           test_time: :datetime
    # test_skipped_column: :text
    #          created_at: :datetime, required
    #          updated_at: :datetime, required

    pending "add some examples to (or delete) #{__FILE__} Attributes"
  end

  describe 'Associations' do
    pending "add some examples to (or delete) #{__FILE__} Attributes"
  end
end
