require 'rails_helper'

RSpec.describe Developer, type: :model do
  has_valid_factory(:developer)

  describe '#indifferent_attributes' do
    let(:developer) { create(:developer) }

    it 'returns the "attributes" hash with indifferent access' do
      developer.attributes.each do |k , v|
        expect(developer.indifferent_attributes[k.to_s]).to eq(v)
        expect(developer.indifferent_attributes[k.to_sym]).to eq(v)
      end
    end
  end

  describe 'Attributes' do
    #      email: :string, required
    #   password: :text, required
    #      first: :string, required
    #     middle: :string
    #       last: :string, required
    #     suffix: :string
    #        dob: :date, required
    # text_array: :text, required
    #  int_array: :integer, required
    # created_at: :datetime, required
    # updated_at: :datetime, required

    [ :first, :last ].each do |nm|
      required_column(:developer, nm) do
        it "is must be at least 2 characters" do
          record.__send__("#{nm}=", 'a')
          expect(record.valid?).to be false
          expect(record.errors[nm.to_sym]).to include("is too short (minimum is 2 characters)")

          record.__send__("#{nm}=", 'ab')
          expect(record.valid?).to be true
          expect(record.save).to be true
        end
      end
    end

    [ :middle, :suffix ].each do |nm|
      optional_column(:developer, nm) do
        it 'cooerces blank values to nil' do
          record[nm] = ''
          expect(record.__send__(nm)).to eq nil
        end
      end
    end

    required_column(:developer, :email, true) do
      it "must be a valid format" do
        record.email = 'sample@sample'
        expect(record.valid?).to be false
        expect(record.errors[:email]).to_not include("can't be blank")
        expect(record.errors[:email]).to include("is invalid")

        record.email = 'valid@email.email'
        expect(record.valid?).to be true
      end

      it "must be case-insensitively unique" do
        expect(record.save).to be true

        not_unique = record.dup
        expect(not_unique.valid?).to be false
        expect(not_unique.errors[:email]).to include("has already been taken")


        not_unique.email.upcase!
        expect(not_unique.email).to eq(record.email.upcase)
        expect(not_unique.valid?).to be false
        expect(not_unique.errors[:email]).to include("has already been taken")
      end
    end

    required_column(:developer, :gender) do
      it "is coorced to a gender enum" do
        record.gender = "Female"
        expect(record.gender).to eq 'F'
        record.gender = "Fe"
        expect(record.gender).to eq 'F'
        record.gender = "Male"
        expect(record.gender).to eq 'M'
        record.gender = "M"
        expect(record.gender).to eq 'M'
        record.gender = "Masdf"
        expect(record.gender).to eq 'M'
        record.gender = "asd"
        expect(record.gender).to eq nil
      end
    end

    optional_column(:developer, :money_col) do
      it "is coorced to a Money Integer" do
        [
          [0, 0],
          ["asdf", 0],
          [100, 100],
          [1.00, 100],
          [10.00, 1000],
          ["10.540", 1054],
          ["$10.54", 1054],
        ].each do |val, expected|
          record.money_col = val
          expect(record.money_col.value).to eq expected
        end
      end
    end

    required_column(:developer, :dob) do
      it "has to be at least 13 years ago" do
        record.dob = 13.years.ago.to_date + 1.day
        expect(record.valid?).to be false
        expect(record.errors[:dob]).to include("You must be at least 13 years old to use this app")

        record.dob = 13.years.ago.to_date
        expect(record.valid?).to be true
        expect(record.errors[:dob]).to be_empty
      end
    end

    optional_column(:developer, :int_array) do
      it "converts values to an integer array" do
        [
          nil,
          'asdf',
          [1, nil, 3]
        ].each do |val|
          record.int_array = val
          expect(record.int_array).to eq([val].flatten.select(&:present?).map(&:to_i))
        end
      end
    end

    optional_column(:developer, :text_array) do
      it "converts values to a text array" do
        [
          nil,
          'asdf',
          [1, nil, 3]
        ].each do |val|
          record.text_array = val
          expect(record.text_array).to eq([val].flatten.select(&:present?).map(&:to_s))
        end
      end
    end

    optional_column(:developer, :bool_col) do
      context 'loose booleans' do
        it "parses to a three-state boolean" do
          BetterRecord.strict_booleans = false
          [ nil, 0, 1, "true", "false", true, false ].each do |val|
            record.bool_col = val
            expect(record.bool_col).to eq(Boolean.parse(val))
          end
        end
      end

      context 'strict booleans' do
        it "parses to a two-state boolean" do
          BetterRecord.strict_booleans = true
          [ nil, 0, 1, "true", "false", true, false ].each do |val|
            record.bool_col = val
            expect(record.bool_col).to eq(Boolean.strict_parse(val))
          end
        end
      end


    end

  end

  describe 'Associations' do
    describe "tasks" do
      let(:t) { described_class.reflect_on_association(:tasks) }

      it "has many" do
        expect(t.macro).to eq(:has_many)
      end

      it "foreign_key is developer_id" do
        expect(t.foreign_key.to_sym).to eq(:developer_id)
      end

      it "is the inverse of developer" do
        expect(t.options[:inverse_of]).to eq(:developer)
      end
    end

    describe "avatar" do
      let(:developer) { create(:developer) }
      let(:avatar_sample) { build(:developer).avatar }

      before(:each) do
        developer.avatar.purge
        developer.reload
      end

      it "is an attachment" do
        expect(build(:developer).avatar).to be_a_kind_of(ActiveStorage::Attached)
      end

      it "is singular" do
        expect(build(:developer).avatar).to be_a_kind_of(ActiveStorage::Attached::One)
      end

      describe 'attachment' do
        let(:t) { described_class.reflect_on_association(:avatar_attachment) }
        it "has one" do
          expect(t.macro).to eq(:has_one)
        end

        it 'is polymorphic' do
          expect(t.options[:as]).to_not be_empty
          expect(t.options[:inverse_of]).to eq(t.options[:as])
          expect(t.foreign_key.to_s).to eq("#{t.options[:as]}_id")
          expect(t.type.to_s).to eq("#{t.options[:as]}_type")
        end

        [ :polymorphic_name, :table_name, :table_name_without_schema, :table_name_with_schema ].each do |default_method|
          describe "when default polymorphic method = :#{default_method}" do
            let(:association_type) do
              BetterRecord.default_polymorphic_method = default_method
              create(:developer).avatar.__send__("#{t.options[:as]}_type")
            end

            current_method = default_method.to_s.sub('_without_schema', '').to_sym

            it "uses #{default_method} as foreign_type" do
              expect(association_type).to eq(described_class.__send__ default_method)
              expect(association_type).to_not eq(described_class.__send__ current_method) unless described_class.__send__(current_method) == described_class.__send__(default_method)
            end
          end
        end
      end

      describe 'blob' do
        let(:t) { described_class.reflect_on_association(:avatar_blob) }

        it "has one through attachment" do
          expect(t.macro).to eq(:has_one)
          expect(t.options[:through]).to eq(:avatar_attachment)
          expect(t.options[:source]).to eq(:blob)
          expect(t.foreign_key.to_sym).to eq(:blob_id)
        end
      end

      it "accepts any image mime_type" do
        png_image_file = File.open(BetterRecord::Engine.root.join('spec', 'factories', 'images', 'avatar.png'))
        svg_image_file = File.open(BetterRecord::Engine.root.join('spec', 'factories', 'images', 'avatar.svg'))
        pdf_file = File.open(BetterRecord::Engine.root.join('spec', 'factories', 'pdfs', 'sample.pdf'))
        developer.avatar.attach(io: pdf_file, filename: 'sample.pdf')
        expect(developer.valid?).to be false
        expect(developer.errors[:avatar]).to include('is not an image file')

        developer.reload
        expect(developer.avatar.attached?).to be false

        developer.avatar.attach(io: png_image_file, filename: 'avatar.png', content_type: 'image/png')
        expect(developer.valid?).to be true
        expect(developer.errors[:avatar]).to be_empty

        developer.reload
        expect(developer.avatar.attached?).to be true

        developer.avatar.purge
        developer.reload

        developer.avatar.attach(io: svg_image_file, filename: 'avatar.svg', content_type: 'image/svg+xml')
        expect(developer.valid?).to be true
        expect(developer.errors[:avatar]).to be_empty

        developer.reload
        expect(developer.avatar.attached?).to be true
      end

      it "is < 500KB" do
        small_image_file = File.open(BetterRecord::Engine.root.join('spec', 'factories', 'images', 'avatar.png'))
        large_image_file = File.open(BetterRecord::Engine.root.join('spec', 'factories', 'images', 'large-avatar.jpg'))

        developer.avatar.attach(io: large_image_file, filename: 'large.jpg', content_type: 'image/jpeg')
        expect(developer.valid?).to be false
        expect(developer.errors[:avatar]).to include('is too large, maximum 500 KB')

        developer.reload
        expect(developer.avatar.attached?).to be false

        developer.avatar.attach(io: small_image_file, filename: 'small.png', content_type: 'image/png')
        expect(developer.valid?).to be true
        expect(developer.errors[:avatar]).to be_empty

        developer.reload
        expect(developer.avatar.attached?).to be true
      end

      it "will not overwrite an existing avatar with an invalid one" do
        small_image_file = File.open(BetterRecord::Engine.root.join('spec', 'factories', 'images', 'avatar.png'))
        large_image_file = File.open(BetterRecord::Engine.root.join('spec', 'factories', 'images', 'large-avatar.jpg'))

        developer.attach_avatar(io: small_image_file, filename: 'small.png', content_type: 'image/png')

        developer.reload
        expect(developer.avatar.attached?).to be true
        expect(developer.last_avatar.attached?).to be true

        developer.avatar.attach(io: large_image_file, filename: 'large.jpg', content_type: 'image/jpeg')
        expect(developer.valid?).to be false
        expect(developer.errors[:avatar]).to include('is too large, maximum 500 KB')

        developer.reload
        expect(developer.avatar.attached?).to be true
        expect(developer.last_avatar.attached?).to be true
      end
    end
  end
end
