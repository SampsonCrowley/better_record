require 'rails_helper'

RSpec.describe BetterRecord::JWT do
  describe '.gen_encryption_key' do
    it 'creates a random 32 byte string' do
      key = described_class.gen_encryption_key
      keys = { "#{key}" => true }

      expect(described_class.gen_encryption_key).to be_a(String)
      expect(described_class.gen_encryption_key.size).to eq 32

      1000000.times do
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

      1000000.times do
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
          val = described_class::CHARACTERS.map { described_class::CHARACTERS[rand(described_class::CHARACTERS.size)] }
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
    it 'encrypts a JWE with .encryption_key and a JWT payload signed by .signing_key' do
      expect(described_class.encode({data: 'stuff'}).split('.').size).to eq 5
      expect(described_class.encode({data: 'stuff'})).to match /[^\.]+\.[^\.]*(\.[^\.]+){3}/
    end
    
    it 'uses direct encryption' do
      expect(described_class.encode({data: 'stuff'}).split('.')[1].size).to eq 0
    end
  end

  describe '.decode' do
    it 'retrieves a JWT payload signed by .signing_key from and a JWE encrypted with .encryption_key'
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
