FactoryBot.define do
  factory :attachment_validation, class: 'BetterRecord::AttachmentValidation' do
    name { 'test' }
    attachment { ActiveStorage::Attachment.new }
  end
end
