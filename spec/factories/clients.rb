FactoryBot.define do
  factory :client do
    first_name 'Some'
    last_name 'Guy'
    sequence(:email) {|n| "client_email_#{n}@email.address" }
  end
end
