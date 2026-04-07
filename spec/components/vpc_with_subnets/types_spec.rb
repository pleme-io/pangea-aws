# frozen_string_literal: true

require 'spec_helper'
require 'pangea/components/aws/vpc_with_subnets/types'

RSpec.describe Pangea::Components::VpcWithSubnets::Types::VpcWithSubnetsAttributes do
  let(:valid_attrs) do
    {
      vpc_cidr: '10.0.0.0/16',
      availability_zones: ['us-east-1a', 'us-east-1b']
    }
  end

  describe '.new' do
    it 'creates attributes with valid input' do
      attrs = described_class.new(valid_attrs)
      expect(attrs.vpc_cidr).to eq('10.0.0.0/16')
      expect(attrs.availability_zones).to eq(['us-east-1a', 'us-east-1b'])
    end

    it 'applies default values' do
      attrs = described_class.new(valid_attrs)
      expect(attrs.enable_dns_hostnames).to eq(true)
      expect(attrs.enable_dns_support).to eq(true)
      expect(attrs.create_private_subnets).to eq(true)
      expect(attrs.create_public_subnets).to eq(true)
      expect(attrs.subnet_bits).to eq(8)
      expect(attrs.name_prefix).to be_nil
    end

    it 'validates CIDR block format' do
      expect {
        described_class.new(valid_attrs.merge(vpc_cidr: 'invalid'))
      }.to raise_error(Dry::Struct::Error)
    end

    it 'validates AZ format' do
      expect {
        described_class.new(valid_attrs.merge(availability_zones: ['invalid-az']))
      }.to raise_error(Dry::Struct::Error)
    end

    it 'constrains subnet_bits between 1 and 16' do
      expect {
        described_class.new(valid_attrs.merge(subnet_bits: 0))
      }.to raise_error(Dry::Struct::Error)

      expect {
        described_class.new(valid_attrs.merge(subnet_bits: 17))
      }.to raise_error(Dry::Struct::Error)

      expect { described_class.new(valid_attrs.merge(subnet_bits: 1)) }.not_to raise_error
      expect { described_class.new(valid_attrs.merge(subnet_bits: 16)) }.not_to raise_error
    end

    it 'allows custom tags' do
      attrs = described_class.new(valid_attrs.merge(
        vpc_tags: { Name: 'my-vpc' },
        common_tags: { Environment: 'test' }
      ))
      expect(attrs.vpc_tags).to eq({ Name: 'my-vpc' })
      expect(attrs.common_tags).to eq({ Environment: 'test' })
    end

    it 'allows disabling public or private subnets' do
      attrs = described_class.new(valid_attrs.merge(create_private_subnets: false))
      expect(attrs.create_private_subnets).to eq(false)
      expect(attrs.create_public_subnets).to eq(true)
    end

    it 'allows custom name_prefix' do
      attrs = described_class.new(valid_attrs.merge(name_prefix: 'my-project'))
      expect(attrs.name_prefix).to eq('my-project')
    end
  end

  describe 'CidrBlock type' do
    it 'accepts standard CIDR formats' do
      type = Pangea::Components::VpcWithSubnets::Types::CidrBlock
      expect { type.call('10.0.0.0/16') }.not_to raise_error
      expect { type.call('192.168.0.0/24') }.not_to raise_error
      expect { type.call('172.16.0.0/12') }.not_to raise_error
    end

    it 'rejects non-CIDR strings' do
      type = Pangea::Components::VpcWithSubnets::Types::CidrBlock
      expect { type.call('not-a-cidr') }.to raise_error(Dry::Types::ConstraintError)
      expect { type.call('10.0.0.0') }.to raise_error(Dry::Types::ConstraintError)
    end
  end

  describe 'AvailabilityZone type' do
    it 'accepts valid AZ formats' do
      type = Pangea::Components::VpcWithSubnets::Types::AvailabilityZone
      expect { type.call('us-east-1a') }.not_to raise_error
      expect { type.call('eu-west-2b') }.not_to raise_error
      expect { type.call('ap-southeast-1c') }.not_to raise_error
    end

    it 'rejects invalid AZ formats' do
      type = Pangea::Components::VpcWithSubnets::Types::AvailabilityZone
      expect { type.call('us-east1a') }.to raise_error(Dry::Types::ConstraintError)
      expect { type.call('invalid') }.to raise_error(Dry::Types::ConstraintError)
    end
  end
end
