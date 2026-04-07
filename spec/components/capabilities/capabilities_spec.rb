# frozen_string_literal: true

require 'spec_helper'
require 'pangea/components/capabilities'

RSpec.describe Pangea::Components::Capabilities do
  describe Pangea::Components::Capabilities::HighAvailability do
    let(:ha_host) do
      obj = Object.new
      obj.define_singleton_method(:high_availability) { @ha }
      obj.define_singleton_method(:availability_zones) { @azs }
      obj.instance_variable_set(:@ha, true)
      obj.instance_variable_set(:@azs, %w[us-east-1a us-east-1b])
      obj.extend(Pangea::Components::Capabilities::HighAvailability)
      obj
    end

    describe '#apply_high_availability' do
      it 'adds multi_az for RDS instances' do
        config = { type: :aws_rds_instance, engine: 'postgres' }
        result = ha_host.apply_high_availability(config)
        expect(result[:multi_az]).to eq(true)
        expect(result[:engine]).to eq('postgres')
      end

      it 'adds automatic_failover for ElastiCache replication groups' do
        config = { type: :aws_elasticache_replication_group }
        result = ha_host.apply_high_availability(config)
        expect(result[:automatic_failover_enabled]).to eq(true)
      end

      it 'returns config unchanged for unrecognized resource types' do
        config = { type: :aws_s3_bucket, bucket: 'test' }
        result = ha_host.apply_high_availability(config)
        expect(result).to eq(config)
      end

      it 'returns config unchanged when high_availability is false' do
        ha_host.instance_variable_set(:@ha, false)
        config = { type: :aws_rds_instance, engine: 'postgres' }
        result = ha_host.apply_high_availability(config)
        expect(result[:multi_az]).to be_nil
        expect(result).to eq(config)
      end

      it 'does not modify the original config hash' do
        config = { type: :aws_rds_instance, engine: 'postgres' }
        original = config.dup
        ha_host.apply_high_availability(config)
        expect(config).to eq(original)
      end
    end
  end

  describe Pangea::Components::Capabilities::Monitoring do
    let(:monitoring_host) do
      obj = Object.new
      obj.define_singleton_method(:enable_monitoring) { @monitoring }
      obj.define_singleton_method(:monitoring_level) { @level }
      obj.instance_variable_set(:@monitoring, true)
      obj.instance_variable_set(:@level, :standard)
      obj.extend(Pangea::Components::Capabilities::Monitoring)
      obj
    end

    describe '#monitoring_config' do
      it 'returns basic monitoring config' do
        monitoring_host.instance_variable_set(:@level, :basic)
        result = monitoring_host.monitoring_config
        expect(result[:detailed_monitoring]).to eq(false)
        expect(result[:log_retention]).to eq(7)
      end

      it 'returns standard monitoring config' do
        result = monitoring_host.monitoring_config
        expect(result[:detailed_monitoring]).to eq(true)
        expect(result[:log_retention]).to eq(30)
      end

      it 'returns enhanced monitoring config with custom_metrics' do
        monitoring_host.instance_variable_set(:@level, :enhanced)
        result = monitoring_host.monitoring_config
        expect(result[:detailed_monitoring]).to eq(true)
        expect(result[:log_retention]).to eq(90)
        expect(result[:custom_metrics]).to eq(true)
      end

      it 'returns empty hash when monitoring is disabled' do
        monitoring_host.instance_variable_set(:@monitoring, false)
        result = monitoring_host.monitoring_config
        expect(result).to eq({})
      end

      it 'returns nil for unrecognized monitoring levels' do
        monitoring_host.instance_variable_set(:@level, :unknown)
        result = monitoring_host.monitoring_config
        expect(result).to be_nil
      end
    end
  end

  describe Pangea::Components::Capabilities::Security do
    let(:security_host) do
      obj = Object.new
      obj.define_singleton_method(:enable_encryption) { @encrypt }
      obj.define_singleton_method(:enable_logging) { @logging }
      obj.instance_variable_set(:@encrypt, true)
      obj.instance_variable_set(:@logging, true)
      obj.extend(Pangea::Components::Capabilities::Security)
      obj
    end

    describe '#apply_security' do
      it 'sets encrypted=true for EBS volumes' do
        config = { type: :aws_ebs_volume, size: 100 }
        result = security_host.apply_security(config)
        expect(result[:encrypted]).to eq(true)
        expect(result[:size]).to eq(100)
      end

      it 'sets storage_encrypted=true for DB instances' do
        config = { type: :aws_db_instance, engine: 'postgres' }
        result = security_host.apply_security(config)
        expect(result[:storage_encrypted]).to eq(true)
      end

      it 'sets logging_enabled for all resource types' do
        config = { type: :aws_s3_bucket }
        result = security_host.apply_security(config)
        expect(result[:logging_enabled]).to eq(true)
      end

      it 'does not set encrypted when encryption is disabled' do
        security_host.instance_variable_set(:@encrypt, false)
        config = { type: :aws_ebs_volume }
        result = security_host.apply_security(config)
        expect(result[:encrypted]).to be_nil
      end

      it 'does not set logging when logging is disabled' do
        security_host.instance_variable_set(:@logging, false)
        config = { type: :aws_s3_bucket }
        result = security_host.apply_security(config)
        expect(result[:logging_enabled]).to be_nil
      end

      it 'does not modify the original config hash' do
        config = { type: :aws_ebs_volume }
        security_host.apply_security(config)
        expect(config).to eq({ type: :aws_ebs_volume })
      end

      it 'applies both encryption and logging together' do
        config = { type: :aws_db_instance }
        result = security_host.apply_security(config)
        expect(result[:storage_encrypted]).to eq(true)
        expect(result[:logging_enabled]).to eq(true)
      end

      it 'does not apply EBS encryption to non-EBS resources' do
        config = { type: :aws_s3_bucket }
        result = security_host.apply_security(config)
        expect(result[:encrypted]).to be_nil
      end

      it 'does not apply DB encryption to non-DB resources' do
        config = { type: :aws_ebs_volume }
        result = security_host.apply_security(config)
        expect(result[:storage_encrypted]).to be_nil
      end
    end
  end
end
