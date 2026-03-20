# frozen_string_literal: true
# Copyright 2025 The Pangea Authors
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'spec_helper'
require 'terraform-synthesizer'
require 'pangea/resources/aws_route53_query_log/resource'

RSpec.describe 'aws_route53_query_log synthesis' do
  let(:synthesizer) { TerraformSynthesizer.new }

  let(:valid_attrs) do
    {
      name: 'test-query-log',
      hosted_zone_id: 'Z0123456789ABCDEFGHIJ',
      destination_arn: 'arn:aws:logs:us-east-1:123456789012:log-group:/aws/route53/example.com'
    }
  end

  describe 'terraform synthesis' do
    it 'synthesizes with valid attributes' do
      attrs = valid_attrs
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_route53_query_log(:test, attrs)
      end

      result = synthesizer.synthesis
      query_log = result[:resource][:aws_route53_query_log][:test]

      expect(query_log[:name]).to eq('test-query-log')
      expect(query_log[:hosted_zone_id]).to eq('Z0123456789ABCDEFGHIJ')
    end

    it 'synthesizes with tags' do
      attrs = valid_attrs.merge(tags: { Environment: 'production' })
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_route53_query_log(:tagged, attrs)
      end

      result = synthesizer.synthesis
      query_log = result[:resource][:aws_route53_query_log][:tagged]

      expect(query_log[:tags][:Environment]).to eq('production')
    end
  end

  describe 'resource references' do
    it 'returns ResourceReference with correct outputs' do
      attrs = valid_attrs
      ref = synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_route53_query_log(:test, attrs)
      end

      expect(ref).to be_a(Pangea::Resources::ResourceReference)
      expect(ref.outputs[:id]).to eq('${aws_route53_query_log.test.id}')
      expect(ref.outputs[:arn]).to eq('${aws_route53_query_log.test.arn}')
    end
  end

  describe 'validation' do
    it 'rejects invalid hosted zone ID format' do
      expect {
        Pangea::Resources::AWS::Types::Route53QueryLogAttributes.new(
          name: 'test-log',
          hosted_zone_id: 'invalid-zone-id',
          destination_arn: 'arn:aws:logs:us-east-1:123456789012:log-group:/aws/route53/example.com'
        )
      }.to raise_error(Dry::Struct::Error)
    end

    it 'rejects invalid CloudWatch Logs ARN format' do
      expect {
        Pangea::Resources::AWS::Types::Route53QueryLogAttributes.new(
          name: 'test-log',
          hosted_zone_id: 'Z0123456789ABCDEFGHIJ',
          destination_arn: 'not-a-valid-arn'
        )
      }.to raise_error(Dry::Struct::Error)
    end
  end
end
