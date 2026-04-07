# frozen_string_literal: true

require 'spec_helper'
require 'pangea/components/aws/secure_vpc/types'

RSpec.describe Pangea::Components::SecureVpc::Types::SecureVpcAttributes do
  let(:valid_attrs) do
    {
      cidr_block: '10.0.0.0/16',
      availability_zones: ['us-east-1a', 'us-east-1b']
    }
  end

  describe '.new' do
    it 'creates attributes with valid input' do
      attrs = described_class.new(valid_attrs)
      expect(attrs.cidr_block).to eq('10.0.0.0/16')
      expect(attrs.availability_zones).to eq(['us-east-1a', 'us-east-1b'])
    end

    it 'applies default values' do
      attrs = described_class.new(valid_attrs)
      expect(attrs.enable_dns_hostnames).to eq(true)
      expect(attrs.enable_dns_support).to eq(true)
      expect(attrs.enable_flow_logs).to eq(true)
      expect(attrs.flow_log_destination).to eq('cloud-watch-logs')
      expect(attrs.tags).to eq({})
    end

    context 'CIDR block validation' do
      it 'rejects CIDR blocks too small (>/28)' do
        expect {
          described_class.new(valid_attrs.merge(cidr_block: '10.0.0.0/29'))
        }.to raise_error(Dry::Struct::Error, /too small/)
      end

      it 'rejects CIDR blocks too large (</16)' do
        expect {
          described_class.new(valid_attrs.merge(cidr_block: '10.0.0.0/15'))
        }.to raise_error(Dry::Struct::Error, /too large/)
      end

      it 'accepts /16 CIDR blocks (boundary)' do
        expect { described_class.new(valid_attrs.merge(cidr_block: '10.0.0.0/16')) }.not_to raise_error
      end

      it 'accepts /28 CIDR blocks (boundary)' do
        expect { described_class.new(valid_attrs.merge(cidr_block: '10.0.0.0/28')) }.not_to raise_error
      end

      it 'accepts /24 CIDR blocks (common)' do
        expect { described_class.new(valid_attrs.merge(cidr_block: '10.0.0.0/24')) }.not_to raise_error
      end
    end

    context 'availability zone validation' do
      it 'rejects AZs from different regions' do
        expect {
          described_class.new(valid_attrs.merge(
            availability_zones: ['us-east-1a', 'us-west-2a']
          ))
        }.to raise_error(Dry::Struct::Error, /same region/)
      end

      it 'accepts AZs from the same region' do
        expect {
          described_class.new(valid_attrs.merge(
            availability_zones: ['eu-west-1a', 'eu-west-1b', 'eu-west-1c']
          ))
        }.not_to raise_error
      end

      it 'skips region validation for single AZ' do
        expect {
          described_class.new(valid_attrs.merge(
            availability_zones: ['us-east-1a']
          ))
        }.not_to raise_error
      end
    end

    context 'flow log destination validation' do
      it 'accepts cloud-watch-logs destination' do
        expect {
          described_class.new(valid_attrs.merge(flow_log_destination: 'cloud-watch-logs'))
        }.not_to raise_error
      end

      it 'accepts s3 destination when flow logs are enabled in security_config' do
        expect {
          described_class.new(valid_attrs.merge(
            flow_log_destination: 's3',
            security_config: { enable_flow_logs: true }
          ))
        }.not_to raise_error
      end

      it 'rejects s3 destination when flow logs are not explicitly enabled in security_config' do
        expect {
          described_class.new(valid_attrs.merge(flow_log_destination: 's3'))
        }.to raise_error(Dry::Struct::Error, /S3 flow log destination requires enable_flow_logs/)
      end
    end
  end

  describe '#region' do
    it 'extracts region from first AZ' do
      attrs = described_class.new(valid_attrs.merge(
        availability_zones: ['eu-central-1a', 'eu-central-1b']
      ))
      expect(attrs.region).to eq('eu-central-1')
    end

    it 'handles AZs with multiple hyphenated region names' do
      attrs = described_class.new(valid_attrs.merge(
        availability_zones: ['ap-southeast-1a', 'ap-southeast-1b']
      ))
      expect(attrs.region).to eq('ap-southeast-1')
    end
  end

  describe '#estimated_subnet_capacity' do
    {
      '10.0.0.0/16' => 256,
      '10.0.0.0/17' => 128,
      '10.0.0.0/18' => 64,
      '10.0.0.0/19' => 32,
      '10.0.0.0/20' => 16,
      '10.0.0.0/21' => 8,
      '10.0.0.0/22' => 4,
      '10.0.0.0/23' => 2,
      '10.0.0.0/24' => 1,
      '10.0.0.0/25' => 0,
      '10.0.0.0/28' => 0
    }.each do |cidr, expected_capacity|
      it "returns #{expected_capacity} for #{cidr}" do
        attrs = described_class.new(valid_attrs.merge(cidr_block: cidr))
        expect(attrs.estimated_subnet_capacity).to eq(expected_capacity)
      end
    end
  end

  describe '#is_rfc1918_private?' do
    it 'returns true for 10.x.x.x addresses' do
      attrs = described_class.new(valid_attrs.merge(cidr_block: '10.0.0.0/16'))
      expect(attrs.is_rfc1918_private?).to eq(true)
    end

    it 'returns true for 10.255.0.0 addresses' do
      attrs = described_class.new(valid_attrs.merge(cidr_block: '10.255.0.0/16'))
      expect(attrs.is_rfc1918_private?).to eq(true)
    end

    it 'returns true for 172.16.x.x addresses' do
      attrs = described_class.new(valid_attrs.merge(cidr_block: '172.16.0.0/16'))
      expect(attrs.is_rfc1918_private?).to eq(true)
    end

    it 'returns true for 172.31.x.x addresses (boundary of 172.16-31)' do
      attrs = described_class.new(valid_attrs.merge(cidr_block: '172.31.0.0/16'))
      expect(attrs.is_rfc1918_private?).to eq(true)
    end

    it 'returns true for 192.168.x.x addresses' do
      attrs = described_class.new(valid_attrs.merge(cidr_block: '192.168.0.0/16'))
      expect(attrs.is_rfc1918_private?).to eq(true)
    end

    it 'returns false for public IP ranges' do
      attrs = described_class.new(valid_attrs.merge(cidr_block: '8.8.0.0/16'))
      expect(attrs.is_rfc1918_private?).to eq(false)
    end

    it 'returns false for 172.15.x.x (just below private range)' do
      attrs = described_class.new(valid_attrs.merge(cidr_block: '172.15.0.0/16'))
      expect(attrs.is_rfc1918_private?).to eq(false)
    end

    it 'returns false for 172.32.x.x (just above private range)' do
      attrs = described_class.new(valid_attrs.merge(cidr_block: '172.32.0.0/16'))
      expect(attrs.is_rfc1918_private?).to eq(false)
    end

    it 'returns false for 192.169.x.x' do
      attrs = described_class.new(valid_attrs.merge(cidr_block: '192.169.0.0/16'))
      expect(attrs.is_rfc1918_private?).to eq(false)
    end
  end

  describe '#security_level' do
    it 'returns maximum when all security features are enabled' do
      attrs = described_class.new(valid_attrs.merge(
        enable_flow_logs: true,
        enable_dns_support: true,
        enable_dns_hostnames: true,
        security_config: { encryption_at_rest: true },
        monitoring_config: { enable_detailed_monitoring: true }
      ))
      expect(attrs.security_level).to eq('maximum')
    end

    it 'returns enhanced for typical config' do
      attrs = described_class.new(valid_attrs.merge(
        enable_flow_logs: true,
        enable_dns_support: true,
        enable_dns_hostnames: true
      ))
      expect(attrs.security_level).to eq('enhanced')
    end

    it 'returns basic when only one feature is enabled' do
      attrs = described_class.new(valid_attrs.merge(
        enable_flow_logs: true,
        enable_dns_support: false,
        enable_dns_hostnames: false
      ))
      expect(attrs.security_level).to eq('basic')
    end

    it 'returns basic when no features are enabled' do
      attrs = described_class.new(valid_attrs.merge(
        enable_flow_logs: false,
        enable_dns_support: false,
        enable_dns_hostnames: false
      ))
      expect(attrs.security_level).to eq('basic')
    end
  end

  describe '#compliance_features' do
    it 'includes VPC Flow Logs when enabled' do
      attrs = described_class.new(valid_attrs.merge(enable_flow_logs: true))
      expect(attrs.compliance_features).to include('VPC Flow Logs')
    end

    it 'excludes VPC Flow Logs when disabled' do
      attrs = described_class.new(valid_attrs.merge(enable_flow_logs: false))
      expect(attrs.compliance_features).not_to include('VPC Flow Logs')
    end

    it 'includes DNS Resolution when both DNS features are enabled' do
      attrs = described_class.new(valid_attrs.merge(
        enable_dns_support: true,
        enable_dns_hostnames: true
      ))
      expect(attrs.compliance_features).to include('DNS Resolution')
    end

    it 'excludes DNS Resolution when dns_support is disabled' do
      attrs = described_class.new(valid_attrs.merge(enable_dns_support: false))
      expect(attrs.compliance_features).not_to include('DNS Resolution')
    end

    it 'includes Private CIDR Range for RFC1918 addresses' do
      attrs = described_class.new(valid_attrs)
      expect(attrs.compliance_features).to include('Private CIDR Range')
    end

    it 'includes CloudWatch Monitoring from monitoring_config' do
      attrs = described_class.new(valid_attrs.merge(
        monitoring_config: { enable_cloudwatch: true }
      ))
      expect(attrs.compliance_features).to include('CloudWatch Monitoring')
    end

    it 'includes Encryption at Rest from security_config' do
      attrs = described_class.new(valid_attrs.merge(
        security_config: { encryption_at_rest: true }
      ))
      expect(attrs.compliance_features).to include('Encryption at Rest')
    end
  end

  describe 'key transforms' do
    it 'accepts string keys and converts to symbols' do
      attrs = described_class.new({
        'cidr_block' => '10.0.0.0/16',
        'availability_zones' => ['us-east-1a']
      })
      expect(attrs.cidr_block).to eq('10.0.0.0/16')
    end
  end
end
