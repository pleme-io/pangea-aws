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
require 'pangea/resources/aws_cloudwatch_log_stream/resource'

RSpec.describe 'aws_cloudwatch_log_stream synthesis' do
  let(:synthesizer) { TerraformSynthesizer.new }

  describe 'terraform synthesis' do
    it 'synthesizes basic log stream' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_cloudwatch_log_stream(:app_stream, {
          name: 'application-instance-001',
          log_group_name: '/application/web-servers'
        })
      end

      result = synthesizer.synthesis
      stream = result['resource']['aws_cloudwatch_log_stream']['app_stream']

      expect(stream['name']).to eq('application-instance-001')
      expect(stream['log_group_name']).to eq('/application/web-servers')
    end

    it 'synthesizes ECS task log stream' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_cloudwatch_log_stream(:ecs_stream, {
          name: 'ecs/web-service/task-12345',
          log_group_name: '/ecs/web-service'
        })
      end

      result = synthesizer.synthesis
      stream = result['resource']['aws_cloudwatch_log_stream']['ecs_stream']

      expect(stream['name']).to eq('ecs/web-service/task-12345')
    end
  end

  describe 'resource references' do
    it 'returns a ResourceReference with correct outputs' do
      ref = nil
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        ref = aws_cloudwatch_log_stream(:test, {
          name: 'test-stream',
          log_group_name: '/test/group'
        })
      end

      expect(ref.outputs[:arn]).to eq('${aws_cloudwatch_log_stream.test.arn}')
      expect(ref.outputs[:name]).to eq('${aws_cloudwatch_log_stream.test.name}')
      expect(ref.outputs[:log_group_name]).to eq('${aws_cloudwatch_log_stream.test.log_group_name}')
    end
  end

  describe 'validation' do
    it 'rejects empty stream name' do
      expect {
        Pangea::Resources::AWS::Types::CloudWatchLogStreamAttributes.new({
          name: '',
          log_group_name: '/test/group'
        })
      }.to raise_error(Dry::Struct::Error, /cannot be empty/)
    end

    it 'rejects stream name exceeding 512 characters' do
      expect {
        Pangea::Resources::AWS::Types::CloudWatchLogStreamAttributes.new({
          name: 'a' * 513,
          log_group_name: '/test/group'
        })
      }.to raise_error(Dry::Struct::Error, /cannot exceed 512/)
    end
  end
end
