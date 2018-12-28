FactoryBot.define do
  factory :client do
    first_name { 'Some' }
    last_name { 'Guy' }
    sequence(:email) {|n| "client_email_#{n}@email.address" }
    after(:create) do |client|
      client.avatar.attach(io: File.open(BetterRecord::Engine.root.join('spec', 'factories', 'images', 'avatar.svg')), filename: 'avatar.svg', content_type: 'image/svg+xml')
    end
  end
end
