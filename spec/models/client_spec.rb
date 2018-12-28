require 'rails_helper'

RSpec.describe Client, type: :model do
  has_valid_factory(:client)

  describe 'Associations' do

    describe "avatar" do
      let(:client) { create(:client) }
      let(:avatar_sample) { build(:client).avatar }

      before(:each) do
        client.avatar.purge
        client.reload
      end

      it "resizes images to < 500KB" do
        small_image_file = File.open(BetterRecord::Engine.root.join('spec', 'factories', 'images', 'avatar.png'))
        large_image_file = File.open(BetterRecord::Engine.root.join('spec', 'factories', 'images', 'large-avatar.jpg'))

        client.avatar.attach(io: large_image_file, filename: 'large.jpg', content_type: 'image/jpeg')
        expect(client.valid?).to be true

        client.reload

        expect(client.avatar.attached?).to be true
        expect(client.last_avatar.attached?).to be true
        expect(client.last_avatar.blob.byte_size).to eq client.avatar.blob.byte_size
      end
    end
  end
end
