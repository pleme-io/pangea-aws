# frozen_string_literal: true

require 'spec_helper'
require 'pangea/components/aws/public_private_subnets/types'

RSpec.describe Pangea::Components::PublicPrivateSubnets::Types::PublicPrivateSubnetsAttributes do
  let(:valid_attrs) do
    {
      vpc_ref: 'vpc-12345678',
      public_cidrs: ['10.0.1.0/24', '10.0.2.0/24'],
      private_cidrs: ['10.0.3.0/24', '10.0.4.0/24'],
      availability_zones: ['us-east-1a', 'us-east-1b']
    }
  end

  describe '.new' do
    it 'creates attributes with valid input' do
      attrs = described_class.new(valid_attrs)
      expect(attrs.vpc_ref).to eq('vpc-12345678')
      expect(attrs.public_cidrs).to eq(['10.0.1.0/24', '10.0.2.0/24'])
      expect(attrs.private_cidrs).to eq(['10.0.3.0/24', '10.0.4.0/24'])
    end

    it 'applies default values' do
      attrs = described_class.new(valid_attrs)
      expect(attrs.create_nat_gateway).to eq(true)
      expect(attrs.nat_gateway_type).to eq('per_az')
      expect(attrs.enable_nat_gateway_monitoring).to eq(true)
      expect(attrs.tags).to eq({})
    end

    context 'CIDR overlap validation' do
      it 'rejects duplicate CIDRs between public and private' do
        expect {
          described_class.new(valid_attrs.merge(
            public_cidrs: ['10.0.1.0/24'],
            private_cidrs: ['10.0.1.0/24']
          ))
        }.to raise_error(Dry::Struct::Error, /Duplicate CIDR/)
      end

      it 'allows non-overlapping CIDRs' do
        expect {
          described_class.new(valid_attrs.merge(
            public_cidrs: ['10.0.1.0/24'],
            private_cidrs: ['10.0.2.0/24']
          ))
        }.not_to raise_error
      end
    end

    context 'high availability validation' do
      it 'rejects HA with insufficient AZs' do
        expect {
          described_class.new(valid_attrs.merge(
            availability_zones: ['us-east-1a'],
            high_availability: { multi_az: true, min_availability_zones: 2 }
          ))
        }.to raise_error(Dry::Struct::Error, /at least 2/)
      end

      it 'rejects uneven distribution when distribute_evenly is true' do
        expect {
          described_class.new(valid_attrs.merge(
            public_cidrs: ['10.0.1.0/24', '10.0.2.0/24', '10.0.5.0/24'],
            private_cidrs: ['10.0.3.0/24', '10.0.4.0/24'],
            availability_zones: ['us-east-1a', 'us-east-1b'],
            high_availability: { distribute_evenly: true }
          ))
        }.to raise_error(Dry::Struct::Error, /Even distribution/)
      end

      it 'accepts even distribution' do
        expect {
          described_class.new(valid_attrs.merge(
            public_cidrs: ['10.0.1.0/24', '10.0.2.0/24'],
            private_cidrs: ['10.0.3.0/24', '10.0.4.0/24'],
            availability_zones: ['us-east-1a', 'us-east-1b'],
            high_availability: { distribute_evenly: true }
          ))
        }.not_to raise_error
      end
    end

    context 'NAT gateway validation' do
      it 'rejects per_az NAT with fewer private subnets than AZs' do
        expect {
          described_class.new(valid_attrs.merge(
            private_cidrs: ['10.0.3.0/24'],
            availability_zones: ['us-east-1a', 'us-east-1b'],
            nat_gateway_type: 'per_az'
          ))
        }.to raise_error(Dry::Struct::Error, /NAT gateway per AZ/)
      end
    end
  end

  describe '#subnet_pairs_count' do
    it 'returns the minimum of public and private subnet counts' do
      attrs = described_class.new(valid_attrs.merge(
        public_cidrs: ['10.0.1.0/24', '10.0.2.0/24', '10.0.5.0/24'],
        private_cidrs: ['10.0.3.0/24', '10.0.4.0/24']
      ))
      expect(attrs.subnet_pairs_count).to eq(2)
    end

    it 'returns count when both are equal' do
      attrs = described_class.new(valid_attrs)
      expect(attrs.subnet_pairs_count).to eq(2)
    end
  end

  describe '#total_subnets_count' do
    it 'returns total of public and private subnets' do
      attrs = described_class.new(valid_attrs)
      expect(attrs.total_subnets_count).to eq(4)
    end
  end

  describe '#nat_gateway_count' do
    it 'returns 0 when NAT gateway is disabled' do
      attrs = described_class.new(valid_attrs.merge(create_nat_gateway: false))
      expect(attrs.nat_gateway_count).to eq(0)
    end

    it 'returns 1 for single NAT gateway type' do
      attrs = described_class.new(valid_attrs.merge(nat_gateway_type: 'single'))
      expect(attrs.nat_gateway_count).to eq(1)
    end

    it 'returns AZ count for per_az NAT gateway type' do
      attrs = described_class.new(valid_attrs)
      expect(attrs.nat_gateway_count).to eq(2)
    end
  end

  describe '#estimated_monthly_nat_cost' do
    it 'returns $0 when NAT is disabled' do
      attrs = described_class.new(valid_attrs.merge(create_nat_gateway: false))
      expect(attrs.estimated_monthly_nat_cost).to eq(0.0)
    end

    it 'returns $45 for single NAT gateway' do
      attrs = described_class.new(valid_attrs.merge(nat_gateway_type: 'single'))
      expect(attrs.estimated_monthly_nat_cost).to eq(45.0)
    end

    it 'returns $90 for 2 per-AZ NAT gateways' do
      attrs = described_class.new(valid_attrs)
      expect(attrs.estimated_monthly_nat_cost).to eq(90.0)
    end
  end

  describe '#high_availability_level' do
    it 'returns none when multi_az is false' do
      attrs = described_class.new(valid_attrs)
      expect(attrs.high_availability_level).to eq('none')
    end

    it 'returns basic for 2 AZs with multi_az' do
      attrs = described_class.new(valid_attrs.merge(
        high_availability: { multi_az: true }
      ))
      expect(attrs.high_availability_level).to eq('basic')
    end

    it 'returns high for 3+ AZs with multi_az' do
      attrs = described_class.new(valid_attrs.merge(
        public_cidrs: ['10.0.1.0/24', '10.0.2.0/24', '10.0.5.0/24'],
        private_cidrs: ['10.0.3.0/24', '10.0.4.0/24', '10.0.6.0/24'],
        availability_zones: ['us-east-1a', 'us-east-1b', 'us-east-1c'],
        high_availability: { multi_az: true }
      ))
      expect(attrs.high_availability_level).to eq('high')
    end
  end

  describe '#subnet_distribution_strategy' do
    it 'returns even_distribution when distribute_evenly is true' do
      attrs = described_class.new(valid_attrs.merge(
        high_availability: { distribute_evenly: true }
      ))
      expect(attrs.subnet_distribution_strategy).to eq('even_distribution')
    end

    it 'returns multi_az_manual for multi-AZ without even distribution' do
      attrs = described_class.new(valid_attrs)
      expect(attrs.subnet_distribution_strategy).to eq('multi_az_manual')
    end

    it 'returns single_az for single AZ' do
      attrs = described_class.new(valid_attrs.merge(
        availability_zones: ['us-east-1a'],
        private_cidrs: ['10.0.3.0/24']
      ))
      expect(attrs.subnet_distribution_strategy).to eq('single_az')
    end
  end

  describe '#networking_pattern' do
    it 'returns hybrid_public_private for mixed subnets' do
      attrs = described_class.new(valid_attrs)
      expect(attrs.networking_pattern).to eq('hybrid_public_private')
    end
  end

  describe '#security_profile' do
    it 'returns maximum with all security features' do
      attrs = described_class.new(valid_attrs.merge(
        nat_gateway_type: 'per_az',
        enable_nat_gateway_monitoring: true,
        high_availability: { multi_az: true }
      ))
      expect(attrs.security_profile).to eq('maximum')
    end

    it 'returns basic with minimal security features' do
      attrs = described_class.new(valid_attrs.merge(
        create_nat_gateway: false,
        enable_nat_gateway_monitoring: false,
        private_cidrs: ['10.0.3.0/24', '10.0.4.0/24']
      ))
      expect(attrs.security_profile).to eq('basic')
    end
  end

  describe 'key transforms' do
    it 'accepts string keys and converts to symbols' do
      attrs = described_class.new({
        'vpc_ref' => 'vpc-123',
        'public_cidrs' => ['10.0.1.0/24'],
        'private_cidrs' => ['10.0.2.0/24'],
        'availability_zones' => ['us-east-1a']
      })
      expect(attrs.vpc_ref).to eq('vpc-123')
    end
  end
end
