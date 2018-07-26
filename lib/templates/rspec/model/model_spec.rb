<% module_namespacing do -%>
require 'rails_helper'

RSpec.describe <%= class_name %>, <%= type_metatag(:model) %> do
  has_valid_factory(:<%= class_name.underscore %>)

  describe 'Attributes' do
    # run `rails spec:attributes <%= class_name -%>` to replace this line

    pending "add some examples to (or delete) #{__FILE__} Attributes"
  end

  describe 'Associations' do
    pending "add some examples to (or delete) #{__FILE__} Attributes"
  end
end
<% end -%>
