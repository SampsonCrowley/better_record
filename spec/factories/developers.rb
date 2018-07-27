FactoryBot.define do
  factory :developer do
    sequence(:email) {|n| "developer_email_#{n}@email.address" }
    new_password 'asdfasdf'
    new_password_confirmation 'asdfasdf'
    first "MyString"
    middle "MyString"
    last "MyString"
    suffix "MyString"
    dob 20.years.ago
    after(:create) do |developer|
      developer.avatar.attach(io: File.open(BetterRecord::Engine.root.join('spec', 'factories', 'images', 'avatar.svg')), filename: 'avatar.svg', content_type: 'image/svg+xml')
    end
  end
end
