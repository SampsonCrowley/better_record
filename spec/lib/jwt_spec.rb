require 'rails_helper'
require 'jwt'

unique_tries = RSpec.configuration.quick_unique? ? 1000 : 1000000

RSpec.describe BetterRecord::JWT do
  before(:each) do
    described_class.signing_key = nil
    described_class.encryption_key = nil
    described_class.encrypt_options = nil
  end
  describe '.gen_encryption_key' do
    it 'creates a random 32 byte string' do
      key = described_class.gen_encryption_key
      keys = { "#{key}" => true }

      expect(described_class.gen_encryption_key).to be_a(String)
      expect(described_class.gen_encryption_key.size).to eq 32

      unique_tries.times do
        k = described_class.gen_encryption_key
        expect(k).to_not eq key
        expect(k.size).to eq 32
        expect(keys[k]).to_not be_truthy
        keys[k] = true
        key = k
      end
      keys = nil
    end
  end

  describe '.gen_signing_key' do
    it 'creates a random string' do
      key = described_class.gen_signing_key
      keys = { key => true }

      expect(described_class.gen_signing_key).to be_a(String)

      unique_tries.times do
        k = described_class.gen_signing_key
        expect(k).to_not eq key
        expect(keys[k]).to_not be_truthy
        keys[k] = true
        key = k
      end
      keys = nil
    end

    it 'defaults to 50 characters' do
      expect(described_class.gen_signing_key.size).to eq 50
    end

    it 'accepts a param to set a string length' do
      500.times do
        l = rand(1000)
        expect(described_class.gen_signing_key(l).size).to eq l
      end
    end
  end

  [
    'encryption_key',
    'signing_key'
  ].each do |m|
    inst_v = "@#{m}".to_sym
    describe ".#{m}" do
      it "is getter for @#{m}" do
        expect(described_class.__send__(m)).to_not be_nil
        expect(described_class.instance_variable_get(inst_v)).to_not be_nil
        expect(described_class.__send__(m)).to eq described_class.instance_variable_get(inst_v)
      end

      it 'sets a new key if empty' do
        old_key = described_class.__send__(m)

        described_class.instance_variable_set(inst_v, nil)
        expect(described_class.instance_variable_get(inst_v)).to be_nil
        expect(described_class.__send__(m)).to_not eq old_key
      end
    end

    describe ".#{m}=" do
      it "is an setter for @#{m}" do
        10.times do
          val = described_class.__send__("gen_#{m}")
          described_class.__send__("#{m}=", val)
          expect(described_class.instance_variable_get(inst_v)).to eq val
          expect(described_class.__send__(m)).to eq val
        end
      end

      it 'generates a new key if nil' do
        old_key = described_class.__send__(m)
        described_class.__send__("#{m}=", nil)
        expect(described_class.instance_variable_get(inst_v)).to_not be_nil
        expect(described_class.__send__(m)).to_not eq old_key
        expect(described_class.__send__(m)).to_not be_nil
      end
    end
  end

  describe ".encrypt_options" do
    it "is getter for @encrypt_options" do
      expect(described_class.encrypt_options).to_not be_nil
      expect(described_class.instance_variable_get(:@encrypt_options)).to_not be_nil
      expect(described_class.encrypt_options).to eq described_class.instance_variable_get(:@encrypt_options)
    end

    it 'reverts to default if empty' do
      old_key = described_class.encrypt_options

      described_class.instance_variable_set(:@encrypt_options, nil)
      expect(described_class.instance_variable_get(:@encrypt_options)).to be_nil
      expect(described_class.encrypt_options).to eq described_class::DEFAULT_OPTIONS
    end
  end

  describe ".encrypt_options=" do
    it "is an setter for @encrypt_options" do
      10.times do
        val = described_class::CHARACTERS.map { described_class::CHARACTERS[rand(described_class::CHARACTERS.size)] }
        described_class.encrypt_options = val
        expect(described_class.instance_variable_get(:@encrypt_options)).to eq val
        expect(described_class.encrypt_options).to eq val
      end
    end

    it 'reverts to default if empty' do
      described_class.encrypt_options = nil
      expect(described_class.instance_variable_get(:@encrypt_options)).to_not be_nil
      expect(described_class.encrypt_options).to eq described_class::DEFAULT_OPTIONS
    end
  end

  describe '.encode' do
    let(:sample_data) { {data: 'stuff'} }
    it 'encrypts a JWE with .encryption_key and a JWT payload signed by .signing_key' do
      expect(described_class.encode(sample_data).split('.').size).to eq 5
      expect(described_class.encode(sample_data)).to match /[^\.]+\.[^\.]*(\.[^\.]+){3}/
      expect { ::JWE.decrypt(described_class.encode(sample_data), described_class.encryption_key) }.to_not raise_error
      expect { ::JWE.decrypt(described_class.encode(sample_data), described_class.gen_encryption_key) }.to raise_error(::JWE::InvalidData)
    end

    it 'uses direct encryption' do
      expect(described_class.encode(sample_data).split('.')[1].size).to eq 0
    end

    it 'is decodable' do
      expect(described_class.decode(described_class.encode(sample_data))).to be_truthy
      expect(described_class.decode(described_class.encode(sample_data))).to be_a(Hash)
      expect(described_class.decode(described_class.encode(sample_data)).keys).to all( be_a(String) )
      expect(described_class.decode(described_class.encode(sample_data)).keys).to eq(sample_data.keys.map(&:to_s))
      expect { described_class.decode(described_class.encode(sample_data)) }.to_not raise_error
      expect { described_class.decode(described_class.encode(sample_data, nil, described_class.gen_encryption_key)) }.to raise_error(::JWE::InvalidData)
      expect { described_class.decode(described_class.encode(sample_data, described_class.gen_signing_key)) }.to raise_error(::JWT::VerificationError)
    end
  end

  describe '.decode' do
    let(:signing_key) { described_class.gen_signing_key }
    let(:encryption_key) { described_class.gen_encryption_key }

    let(:sample_data) { described_class.encode({data: 'stuff'}, signing_key, encryption_key) }

    it 'retrieves a JWT payload signed by .signing_key from a JWE encrypted with .encryption_key' do
      expect { described_class.decode(sample_data, signing_key, encryption_key) }.to_not raise_error
      expect { described_class.decode(sample_data, signing_key, described_class.gen_encryption_key) }.to raise_error(::JWE::InvalidData)
      force_decoded = ::JWT.decode(::JWE.decrypt(sample_data, encryption_key), signing_key, true, algorithm: 'HS512').first
      expect(described_class.decode(sample_data, signing_key, encryption_key)).to eq(force_decoded)
    end
  end

  [
    :create,
    :encrypt,
    :inflate
  ].each do |m|
    describe ".#{m}" do
      it 'is an alias for encode' do
        expect(described_class.method(m)).to eq(described_class.method(:encode))
      end
    end
  end

  [
    :read,
    :decode,
    :deflate
  ].each do |m|
    describe ".#{m}" do
      it 'is an alias for decode' do
        expect(described_class.method(m)).to eq(described_class.method(:decode))
      end
    end
  end
end
