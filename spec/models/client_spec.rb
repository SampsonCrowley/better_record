require 'rails_helper'

RSpec.describe Client, type: :model do
  has_valid_factory(:client)

  describe 'Associations' do

    describe "avatar" do
      let(:client) { create(:client) }

      # before(:each) do
      #   client.avatar.purge if client.avatar.attached?
      #   client.reload
      # end

      it "resizes images to < 500KB" do
        puts "TESTES"
        large_image_file = File.open(BetterRecord::Engine.root.join('spec', 'factories', 'images', 'large-avatar.jpg'))

        puts client.avatar.attach(io: large_image_file, filename: 'large.jpg', content_type: 'image/jpeg')

        expect(BetterRecord::ResizeBlobImageJob).to have_been_enqueued.at_least(1).times

        expect(client.valid?).to be true

        client.reload

        expect(client.avatar.attached?).to be true
        # expect(client.last_avatar.attached?).to be true
        # expect(client.last_avatar.blob.byte_size).to eq client.avatar.blob.byte_size
      end
    end
  end
end
