# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Pangea::Resources::AWSDataSsmParameter do
  include Pangea::Testing::SynthesisTestHelpers

  let(:required_attrs) { { name: '/my/param' } }

  describe ':data_aws_ssm_parameter' do
    context 'with required attributes only' do
      it 'synthesizes valid Terraform JSON with data block' do
        synth = create_synthesizer
        synth.extend(described_class)
        synth.data_aws_ssm_parameter('test', required_attrs)
        result = normalize_synthesis(synth.synthesis)

        validate_terraform_structure(result, :data_source)
        expect(result['data']).to have_key('aws_ssm_parameter')
        expect(result['data']['aws_ssm_parameter']).to have_key('test')

        config = result['data']['aws_ssm_parameter']['test']
        expect(config).to be_a(Hash)
        expect(config).to have_key('name')
      end

      it 'does not produce a resource block' do
        synth = create_synthesizer
        synth.extend(described_class)
        synth.data_aws_ssm_parameter('test', required_attrs)
        result = normalize_synthesis(synth.synthesis)

        expect(result).not_to have_key('resource')
      end

      it 'returns a ResourceReference' do
        synth = create_synthesizer
        synth.extend(described_class)
        ref = synth.data_aws_ssm_parameter('test', required_attrs)

        expect(ref).to be_a(Pangea::Resources::ResourceReference)
        expect(ref.resource_type).to eq(:"data.aws_ssm_parameter")
      end

      it 'provides output references with data prefix' do
        synth = create_synthesizer
        synth.extend(described_class)
        ref = synth.data_aws_ssm_parameter('test', required_attrs)

        expect(ref.id).to eq('${data.aws_ssm_parameter.test.id}')
        expect(ref.value).to eq('${data.aws_ssm_parameter.test.value}')
        expect(ref.outputs[:type]).to eq('${data.aws_ssm_parameter.test.type}')
        expect(ref.arn).to eq('${data.aws_ssm_parameter.test.arn}')
        expect(ref.version).to eq('${data.aws_ssm_parameter.test.version}')
      end
    end

    context 'with optional attributes' do
      it 'includes with_decryption when provided' do
        synth = create_synthesizer
        synth.extend(described_class)
        synth.data_aws_ssm_parameter('test', required_attrs.merge(with_decryption: true))
        result = normalize_synthesis(synth.synthesis)

        config = result['data']['aws_ssm_parameter']['test']
        expect(config).to have_key('with_decryption')
        expect(config['with_decryption']).to eq(true)
      end

      it 'omits with_decryption when not provided' do
        synth = create_synthesizer
        synth.extend(described_class)
        synth.data_aws_ssm_parameter('test', required_attrs)
        result = normalize_synthesis(synth.synthesis)

        config = result['data']['aws_ssm_parameter']['test']
        expect(config).not_to have_key('with_decryption')
      end
    end

    context 'boolean fields' do
      [true, false].each do |val|
        it "accepts with_decryption=#{val}" do
          synth = create_synthesizer
          synth.extend(described_class)
          synth.data_aws_ssm_parameter("bool_#{val}", required_attrs.merge(with_decryption: val))
          result = normalize_synthesis(synth.synthesis)

          config = result['data']['aws_ssm_parameter']["bool_#{val}"]
          expect(config['with_decryption']).to eq(val)
        end
      end
    end

    context 'multiple instances' do
      it 'synthesizes multiple data sources independently' do
        synth = create_synthesizer
        synth.extend(described_class)
        synth.data_aws_ssm_parameter('first', required_attrs)
        synth.data_aws_ssm_parameter('second', { name: '/other/param' })
        result = normalize_synthesis(synth.synthesis)

        data_sources = result.dig('data', 'aws_ssm_parameter')
        expect(data_sources.keys).to contain_exactly('first', 'second')
      end
    end

    context 'attribute types' do
      it 'validates expected attribute types' do
        synth = create_synthesizer
        synth.extend(described_class)
        synth.data_aws_ssm_parameter('typed', required_attrs)
        result = normalize_synthesis(synth.synthesis)

        config = result['data']['aws_ssm_parameter']['typed']
        expect(config['name']).to be_a(String)
      end
    end
  end
end
