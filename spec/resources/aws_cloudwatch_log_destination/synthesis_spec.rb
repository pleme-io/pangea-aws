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
require 'pangea/resources/aws_cloudwatch_log_destination/resource'

RSpec.describe 'aws_cloudwatch_log_destination synthesis' do
  let(:synthesizer) { TerraformSynthesizer.new }

  describe 'terraform synthesis' do
    it 'synthesizes basic log destination' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_cloudwatch_log_destination(:central_logs, {
          name: 'central-log-aggregation',
          role_arn: 'arn:aws:iam::123456789012:role/log-dest-role',
          target_arn: 'arn:aws:kinesis:us-east-1:123456789012:stream/central-logs'
        })
      end

      result = synthesizer.synthesis
      dest = result['resource']['aws_cloudwatch_logs_destination']['central_logs']

      expect(dest['name']).to eq('central-log-aggregation')
      expect(dest['role_arn']).to eq('arn:aws:iam::123456789012:role/log-dest-role')
      expect(dest['target_arn']).to eq('arn:aws:kinesis:us-east-1:123456789012:stream/central-logs')
    end

    it 'synthesizes log destination with tags' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_cloudwatch_log_destination(:tagged, {
          name: 'tagged-dest',
          role_arn: 'arn:aws:iam::123456789012:role/log-role',
          target_arn: 'arn:aws:kinesis:us-east-1:123456789012:stream/logs',
          tags: { Purpose: 'cross-account-aggregation' }
        })
      end

      result = synthesizer.synthesis
      dest = result['resource']['aws_cloudwatch_logs_destination']['tagged']

      expect(dest['tags']['Purpose']).to eq('cross-account-aggregation')
    end
  end

  describe 'resource references' do
    it 'returns a ResourceReference with correct outputs' do
      ref = nil
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        ref = aws_cloudwatch_log_destination(:test, {
          name: 'test-dest',
          role_arn: 'arn:aws:iam::123456789012:role/test-role',
          target_arn: 'arn:aws:kinesis:us-east-1:123456789012:stream/test'
        })
      end

      expect(ref.outputs[:arn]).to eq('${aws_cloudwatch_logs_destination.test.arn}')
      expect(ref.outputs[:name]).to eq('${aws_cloudwatch_logs_destination.test.name}')
    end
  end

  describe 'validation' do
    it 'rejects invalid role ARN' do
      expect {
        Pangea::Resources::AWS::Types::CloudWatchLogDestinationAttributes.new({
          name: 'test',
          role_arn: 'invalid-arn',
          target_arn: 'arn:aws:kinesis:us-east-1:123456789012:stream/test'
        })
      }.to raise_error(Dry::Struct::Error, /role_arn must be a valid/)
    end
  end
end
