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
require 'pangea/resources/aws_cloudwatch_query_definition/resource'

RSpec.describe 'aws_cloudwatch_query_definition synthesis' do
  let(:synthesizer) { TerraformSynthesizer.new }

  describe 'terraform synthesis' do
    it 'synthesizes basic query definition' do
      pending 'Base.transform_attributes not yet implemented in pangea-core'
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_cloudwatch_query_definition(:error_analysis, {
          name: 'Application Error Analysis',
          query_string: "fields @timestamp, @message | filter @message like /ERROR/ | sort @timestamp desc"
        })
      end

      result = synthesizer.synthesis
      query = result[:resource][:aws_cloudwatch_query_definition][:error_analysis]

      expect(query[:name]).to eq('Application Error Analysis')
    end

    it 'synthesizes query definition with log group names' do
      pending 'Base.transform_attributes not yet implemented in pangea-core'
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_cloudwatch_query_definition(:with_groups, {
          name: 'Multi Group Query',
          query_string: "fields @timestamp, @message",
          log_group_names: ['/aws/lambda/func1', '/aws/lambda/func2']
        })
      end

      result = synthesizer.synthesis
      query = result[:resource][:aws_cloudwatch_query_definition][:with_groups]

      expect(query[:log_group_names]).to include('/aws/lambda/func1')
    end
  end

  describe 'resource references' do
    it 'provides correct terraform interpolation strings' do
      pending 'Base.transform_attributes not yet implemented in pangea-core'
      ref = synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_cloudwatch_query_definition(:test, {
          name: 'Test Query',
          query_string: 'fields @timestamp'
        })
      end

      expect(ref.outputs[:arn]).to eq('${aws_cloudwatch_query_definition.test.arn}')
    end
  end
end
