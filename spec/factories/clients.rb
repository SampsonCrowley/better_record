FactoryBot.define do
  factory :client do
    first_name { 'Some' }
    last_name { 'Guy' }
    sequence(:email) {|n| "client_email_#{n}@email.address" }
    # after(:create) do |client|
    #   client.avatar.attach(io: File.open(BetterRecord::Engine.root.join('spec', 'factories', 'images', 'large-avatar.jpg')), filename: 'avatar.jpg', content_type: 'image/jpg')
    # end
  end
end
