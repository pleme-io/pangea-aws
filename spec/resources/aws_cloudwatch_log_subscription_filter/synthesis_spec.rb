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
require 'pangea/resources/aws_cloudwatch_log_subscription_filter/resource'

RSpec.describe 'aws_cloudwatch_log_subscription_filter synthesis' do
  let(:synthesizer) { TerraformSynthesizer.new }

  describe 'terraform synthesis' do
    it 'synthesizes basic subscription filter' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_cloudwatch_log_subscription_filter(:all_logs, {
          name: 'stream-all-logs',
          log_group_name: '/aws/lambda/my-function',
          destination_arn: 'arn:aws:logs:us-east-1:123456789012:destination:central',
          filter_pattern: ''
        })
      end

      result = synthesizer.synthesis
      filter = result['resource']['aws_cloudwatch_log_subscription_filter']['all_logs']

      expect(filter['name']).to eq('stream-all-logs')
      expect(filter['log_group_name']).to eq('/aws/lambda/my-function')
      expect(filter['destination_arn']).to eq('arn:aws:logs:us-east-1:123456789012:destination:central')
    end

    it 'synthesizes filter with pattern and role' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_cloudwatch_log_subscription_filter(:errors, {
          name: 'error-filter',
          log_group_name: '/aws/lambda/api',
          destination_arn: 'arn:aws:lambda:us-east-1:123456789012:function:processor',
          filter_pattern: 'ERROR',
          role_arn: 'arn:aws:iam::123456789012:role/lambda-invoke'
        })
      end

      result = synthesizer.synthesis
      filter = result['resource']['aws_cloudwatch_log_subscription_filter']['errors']

      expect(filter['filter_pattern']).to eq('ERROR')
      expect(filter['role_arn']).to eq('arn:aws:iam::123456789012:role/lambda-invoke')
    end
  end

  describe 'resource references' do
    it 'returns a ResourceReference with correct outputs' do
      ref = nil
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        ref = aws_cloudwatch_log_subscription_filter(:test, {
          name: 'test-filter',
          log_group_name: '/test/group',
          destination_arn: 'arn:aws:logs:us-east-1:123456789012:destination:test'
        })
      end

      expect(ref.outputs[:id]).to eq('${aws_cloudwatch_log_subscription_filter.test.id}')
      expect(ref.outputs[:name]).to eq('${aws_cloudwatch_log_subscription_filter.test.name}')
      expect(ref.outputs[:destination_arn]).to eq('${aws_cloudwatch_log_subscription_filter.test.destination_arn}')
    end
  end

  describe 'validation' do
    it 'rejects invalid destination ARN' do
      expect {
        Pangea::Resources::AWS::Types::CloudWatchLogSubscriptionFilterAttributes.new({
          name: 'test',
          log_group_name: '/test/group',
          destination_arn: 'invalid-arn'
        })
      }.to raise_error(Dry::Struct::Error, /destination_arn must be a valid ARN/)
    end
  end
end
