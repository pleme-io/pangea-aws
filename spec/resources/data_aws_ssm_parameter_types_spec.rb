# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Pangea::Resources::AWS::Types::DataSsmParameterAttributes do
  describe '.new' do
    it 'creates attributes with required name' do
      attrs = described_class.new(name: '/my/param')
      expect(attrs.name).to eq('/my/param')
    end

    it 'raises error when name is missing' do
      expect {
        described_class.new({})
      }.to raise_error(Dry::Struct::Error)
    end

    it 'accepts with_decryption as true' do
      attrs = described_class.new(name: '/my/param', with_decryption: true)
      expect(attrs.with_decryption).to eq(true)
    end

    it 'accepts with_decryption as false' do
      attrs = described_class.new(name: '/my/param', with_decryption: false)
      expect(attrs.with_decryption).to eq(false)
    end

    it 'allows with_decryption to be nil (optional)' do
      attrs = described_class.new(name: '/my/param', with_decryption: nil)
      expect(attrs.with_decryption).to be_nil
    end

    it 'does not require with_decryption' do
      attrs = described_class.new(name: '/my/param')
      expect(attrs.to_h).not_to have_key(:with_decryption)
    end

    it 'accepts path-style parameter names' do
      attrs = described_class.new(name: '/app/database/password')
      expect(attrs.name).to eq('/app/database/password')
    end

    it 'accepts simple parameter names' do
      attrs = described_class.new(name: 'my-parameter')
      expect(attrs.name).to eq('my-parameter')
    end

    it 'transforms string keys to symbols' do
      attrs = described_class.new('name' => '/my/param')
      expect(attrs.name).to eq('/my/param')
    end

    it 'rejects non-string name values' do
      expect {
        described_class.new(name: 123)
      }.to raise_error(Dry::Struct::Error)
    end

    it 'rejects non-boolean with_decryption values' do
      expect {
        described_class.new(name: '/my/param', with_decryption: 'yes')
      }.to raise_error(Dry::Struct::Error)
    end
  end
end
