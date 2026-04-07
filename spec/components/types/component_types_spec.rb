# frozen_string_literal: true

require 'spec_helper'
require 'pangea/components/types'

RSpec.describe Pangea::Components::Types do
  describe 'AvailabilityZones' do
    it 'accepts valid AZ arrays (1-6 elements)' do
      expect { Pangea::Components::Types::AvailabilityZones.call(['us-east-1a']) }.not_to raise_error
      expect { Pangea::Components::Types::AvailabilityZones.call(['us-east-1a', 'us-east-1b']) }.not_to raise_error
    end

    it 'rejects empty arrays' do
      expect { Pangea::Components::Types::AvailabilityZones.call([]) }.to raise_error(Dry::Types::ConstraintError)
    end

    it 'rejects arrays with more than 6 elements' do
      azs = (1..7).map { |i| "us-east-1#{('a'.ord + i - 1).chr}" }
      expect { Pangea::Components::Types::AvailabilityZones.call(azs) }.to raise_error(Dry::Types::ConstraintError)
    end

    it 'rejects invalid AZ formats' do
      expect { Pangea::Components::Types::AvailabilityZones.call(['invalid-az']) }.to raise_error(Dry::Types::ConstraintError)
    end
  end

  describe 'SubnetCidrBlocks' do
    it 'accepts valid CIDR arrays' do
      expect { Pangea::Components::Types::SubnetCidrBlocks.call(['10.0.1.0/24']) }.not_to raise_error
    end

    it 'rejects empty arrays' do
      expect { Pangea::Components::Types::SubnetCidrBlocks.call([]) }.to raise_error(Dry::Types::ConstraintError)
    end

    it 'rejects arrays with more than 10 elements' do
      cidrs = (1..11).map { |i| "10.0.#{i}.0/24" }
      expect { Pangea::Components::Types::SubnetCidrBlocks.call(cidrs) }.to raise_error(Dry::Types::ConstraintError)
    end

    it 'rejects invalid CIDR formats' do
      expect { Pangea::Components::Types::SubnetCidrBlocks.call(['not-a-cidr']) }.to raise_error(Dry::Types::ConstraintError)
    end
  end

  describe 'ComponentName' do
    it 'accepts valid names starting with a letter' do
      expect { Pangea::Components::Types::ComponentName.call('my-component') }.not_to raise_error
      expect { Pangea::Components::Types::ComponentName.call('MyComponent_1') }.not_to raise_error
    end

    it 'rejects names starting with a number' do
      expect { Pangea::Components::Types::ComponentName.call('1invalid') }.to raise_error(Dry::Types::ConstraintError)
    end

    it 'rejects names starting with special characters' do
      expect { Pangea::Components::Types::ComponentName.call('-invalid') }.to raise_error(Dry::Types::ConstraintError)
    end

    it 'rejects names longer than 64 characters' do
      long_name = 'a' * 65
      expect { Pangea::Components::Types::ComponentName.call(long_name) }.to raise_error(Dry::Types::ConstraintError)
    end

    it 'accepts names exactly 64 characters' do
      name = 'a' * 64
      expect { Pangea::Components::Types::ComponentName.call(name) }.not_to raise_error
    end
  end

  describe 'NetworkTopology' do
    %w[single-tier two-tier three-tier multi-tier].each do |topology|
      it "accepts '#{topology}'" do
        expect(Pangea::Components::Types::NetworkTopology.call(topology)).to eq(topology)
      end
    end

    it 'rejects invalid topologies' do
      expect { Pangea::Components::Types::NetworkTopology.call('four-tier') }.to raise_error(Dry::Types::ConstraintError)
    end
  end

  describe 'DeploymentPattern' do
    %w[development staging production disaster-recovery].each do |pattern|
      it "accepts '#{pattern}'" do
        expect(Pangea::Components::Types::DeploymentPattern.call(pattern)).to eq(pattern)
      end
    end

    it 'rejects invalid deployment patterns' do
      expect { Pangea::Components::Types::DeploymentPattern.call('test') }.to raise_error(Dry::Types::ConstraintError)
    end
  end

  describe 'SecurityGroupRules' do
    it 'defaults to an empty array' do
      result = Pangea::Components::Types::SecurityGroupRules.call(Dry::Types::Undefined)
      expect(result).to eq([])
    end

    it 'accepts an array of hashes' do
      rules = [{ from_port: 80, to_port: 80, protocol: 'tcp' }]
      expect { Pangea::Components::Types::SecurityGroupRules.call(rules) }.not_to raise_error
    end
  end

  describe 'SubnetCidrDistribution' do
    it 'accepts valid non-overlapping CIDRs' do
      dist = {
        public_cidrs: ['10.0.1.0/24', '10.0.2.0/24'],
        private_cidrs: ['10.0.3.0/24', '10.0.4.0/24']
      }
      expect { Pangea::Components::Types::SubnetCidrDistribution.call(dist) }.not_to raise_error
    end

    it 'rejects duplicate CIDR blocks across tiers' do
      dist = {
        public_cidrs: ['10.0.1.0/24'],
        private_cidrs: ['10.0.1.0/24']
      }
      expect { Pangea::Components::Types::SubnetCidrDistribution.call(dist) }.to raise_error(Dry::Types::ConstraintError, /Duplicate CIDR/)
    end

    it 'requires at least one public CIDR' do
      dist = {
        public_cidrs: [],
        private_cidrs: ['10.0.1.0/24']
      }
      expect { Pangea::Components::Types::SubnetCidrDistribution.call(dist) }.to raise_error(Dry::Types::ConstraintError)
    end

    it 'accepts distribution without private or database CIDRs' do
      dist = { public_cidrs: ['10.0.1.0/24'] }
      expect { Pangea::Components::Types::SubnetCidrDistribution.call(dist) }.not_to raise_error
    end

    it 'accepts all three tiers of CIDRs' do
      dist = {
        public_cidrs: ['10.0.1.0/24'],
        private_cidrs: ['10.0.2.0/24'],
        database_cidrs: ['10.0.3.0/24']
      }
      expect { Pangea::Components::Types::SubnetCidrDistribution.call(dist) }.not_to raise_error
    end

    it 'detects duplicates across all three tiers' do
      dist = {
        public_cidrs: ['10.0.1.0/24'],
        private_cidrs: ['10.0.2.0/24'],
        database_cidrs: ['10.0.1.0/24']
      }
      expect { Pangea::Components::Types::SubnetCidrDistribution.call(dist) }.to raise_error(Dry::Types::ConstraintError, /Duplicate CIDR/)
    end
  end

  describe 'HighAvailabilityConfig' do
    it 'defaults to an empty hash with default values' do
      result = Pangea::Components::Types::HighAvailabilityConfig.call(Dry::Types::Undefined)
      expect(result).to be_a(Hash)
    end

    it 'accepts valid HA configuration' do
      config = { multi_az: true, min_availability_zones: 3, distribute_evenly: true }
      result = Pangea::Components::Types::HighAvailabilityConfig.call(config)
      expect(result[:multi_az]).to eq(true)
    end
  end

  describe 'SecurityConfig' do
    it 'defaults to an empty hash' do
      result = Pangea::Components::Types::SecurityConfig.call(Dry::Types::Undefined)
      expect(result).to be_a(Hash)
    end

    it 'accepts valid flow log destinations' do
      config = { flow_log_destination: 'cloud-watch-logs' }
      result = Pangea::Components::Types::SecurityConfig.call(config)
      expect(result[:flow_log_destination]).to eq('cloud-watch-logs')
    end

    it 'accepts s3 flow log destination' do
      config = { flow_log_destination: 's3' }
      result = Pangea::Components::Types::SecurityConfig.call(config)
      expect(result[:flow_log_destination]).to eq('s3')
    end

    it 'rejects invalid flow log destinations' do
      config = { flow_log_destination: 'kinesis' }
      expect { Pangea::Components::Types::SecurityConfig.call(config) }.to raise_error(Dry::Types::SchemaError)
    end
  end

  describe 'MonitoringConfig' do
    it 'constrains log_retention_days between 1 and 3653' do
      expect { Pangea::Components::Types::MonitoringConfig.call({ log_retention_days: 0 }) }.to raise_error(Dry::Types::SchemaError)
      expect { Pangea::Components::Types::MonitoringConfig.call({ log_retention_days: 3654 }) }.to raise_error(Dry::Types::SchemaError)

      result = Pangea::Components::Types::MonitoringConfig.call({ log_retention_days: 365 })
      expect(result[:log_retention_days]).to eq(365)
    end
  end

  describe 'AutoScalingConfig' do
    it 'constrains min_size >= 0' do
      expect { Pangea::Components::Types::AutoScalingConfig.call({ min_size: -1 }) }.to raise_error(Dry::Types::SchemaError)
    end

    it 'constrains max_size >= 1' do
      expect { Pangea::Components::Types::AutoScalingConfig.call({ max_size: 0 }) }.to raise_error(Dry::Types::SchemaError)
    end
  end

  describe 'PortConfig' do
    it 'uses correct default ports' do
      result = Pangea::Components::Types::PortConfig.call(Dry::Types::Undefined)
      expect(result).to be_a(Hash)
    end
  end

  describe 'TaggingConfig' do
    it 'defaults to an empty hash' do
      result = Pangea::Components::Types::TaggingConfig.call(Dry::Types::Undefined)
      expect(result).to be_a(Hash)
    end

    it 'accepts optional tagging fields' do
      config = { environment: 'production', project: 'my-project', owner: 'team-a' }
      result = Pangea::Components::Types::TaggingConfig.call(config)
      expect(result[:environment]).to eq('production')
    end
  end
end
