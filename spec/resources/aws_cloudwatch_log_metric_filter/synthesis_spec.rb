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
require 'pangea/resources/aws_cloudwatch_log_metric_filter/resource'

RSpec.describe 'aws_cloudwatch_log_metric_filter synthesis' do
  let(:synthesizer) { TerraformSynthesizer.new }

  describe 'terraform synthesis' do
    it 'synthesizes basic metric filter' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_cloudwatch_log_metric_filter(:error_counter, {
          name: 'application-errors',
          log_group_name: '/aws/lambda/my-function',
          pattern: 'ERROR',
          metric_transformation: {
            name: 'ErrorCount',
            namespace: 'Application/Metrics',
            value: '1',
            default_value: 0.0
          }
        })
      end

      result = synthesizer.synthesis
      filter = result['resource']['aws_cloudwatch_log_metric_filter']['error_counter']

      expect(filter['name']).to eq('application-errors')
      expect(filter['log_group_name']).to eq('/aws/lambda/my-function')
      expect(filter['pattern']).to eq('ERROR')
    end

    it 'synthesizes metric filter with metric transformation' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_cloudwatch_log_metric_filter(:latency, {
          name: 'api-latency',
          log_group_name: '/aws/lambda/api',
          pattern: 'latency',
          metric_transformation: {
            name: 'APILatency',
            namespace: 'API/Performance',
            value: '1'
          }
        })
      end

      result = synthesizer.synthesis
      filter = result['resource']['aws_cloudwatch_log_metric_filter']['latency']

      expect(filter['metric_transformation']['name']).to eq('APILatency')
      expect(filter['metric_transformation']['namespace']).to eq('API/Performance')
    end
  end

  describe 'resource references' do
    it 'returns a ResourceReference with correct outputs' do
      ref = nil
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        ref = aws_cloudwatch_log_metric_filter(:test, {
          name: 'test-filter',
          log_group_name: '/test/group',
          pattern: 'ERROR',
          metric_transformation: {
            name: 'TestMetric',
            namespace: 'Test/Namespace',
            value: '1'
          }
        })
      end

      expect(ref.outputs[:id]).to eq('${aws_cloudwatch_log_metric_filter.test.id}')
      expect(ref.outputs[:name]).to eq('${aws_cloudwatch_log_metric_filter.test.name}')
    end
  end

  describe 'validation' do
    it 'rejects empty pattern' do
      expect {
        Pangea::Resources::AWS::Types::CloudWatchLogMetricFilterAttributes.new({
          name: 'test',
          log_group_name: '/test/group',
          pattern: '   ',
          metric_transformation: { name: 'Test', namespace: 'NS', value: '1' }
        })
      }.to raise_error(Dry::Struct::Error, /pattern cannot be empty/)
    end
  end
end
