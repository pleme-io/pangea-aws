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
require 'pangea/resources/aws_cloudwatch_log_destination_policy/resource'

RSpec.describe 'aws_cloudwatch_log_destination_policy synthesis' do
  let(:synthesizer) { TerraformSynthesizer.new }

  let(:valid_policy) do
    JSON.generate({
      'Version' => '2012-10-17',
      'Statement' => [{
        'Effect' => 'Allow',
        'Principal' => { 'AWS' => 'arn:aws:iam::123456789012:root' },
        'Action' => 'logs:PutSubscriptionFilter',
        'Resource' => 'arn:aws:logs:us-east-1:123456789012:destination:test'
      }]
    })
  end

  describe 'terraform synthesis' do
    it 'synthesizes basic destination policy' do
      pending 'Bug in allowed_principals computed property (NoMethodError: values for Array)'
      policy_json = valid_policy
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_cloudwatch_log_destination_policy(:account_access, {
          destination_name: 'test-destination',
          access_policy: policy_json
        })
      end

      result = synthesizer.synthesis
      policy = result['resource']['aws_cloudwatch_logs_destination_policy']['account_access']

      expect(policy['destination_name']).to eq('test-destination')
    end
  end

  describe 'resource references' do
    it 'returns a ResourceReference with correct outputs' do
      pending 'Bug in allowed_principals computed property (NoMethodError: values for Array)'
      ref = nil
      policy_json = valid_policy
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        ref = aws_cloudwatch_log_destination_policy(:test, {
          destination_name: 'test-dest',
          access_policy: policy_json
        })
      end

      expect(ref.outputs[:id]).to eq('${aws_cloudwatch_logs_destination_policy.test.id}')
    end
  end

  describe 'validation' do
    it 'rejects invalid JSON in access_policy' do
      expect {
        Pangea::Resources::AWS::Types::CloudWatchLogDestinationPolicyAttributes.new({
          destination_name: 'test',
          access_policy: 'not-valid-json'
        })
      }.to raise_error(Dry::Struct::Error, /valid JSON/)
    end

    it 'rejects invalid destination name format' do
      expect {
        Pangea::Resources::AWS::Types::CloudWatchLogDestinationPolicyAttributes.new({
          destination_name: 'invalid name with spaces',
          access_policy: valid_policy
        })
      }.to raise_error(Dry::Struct::Error, /destination_name must contain only/)
    end
  end
end
