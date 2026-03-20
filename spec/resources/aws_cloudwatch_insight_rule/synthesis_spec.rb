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
require 'pangea/resources/aws_cloudwatch_insight_rule/resource'

RSpec.describe 'aws_cloudwatch_insight_rule synthesis' do
  let(:synthesizer) { TerraformSynthesizer.new }

  describe 'terraform synthesis' do
    it 'synthesizes basic insight rule' do
      pending 'Base.transform_attributes not yet implemented in pangea-core'
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_cloudwatch_insight_rule(:app_perf, {
          name: 'ApplicationPerformanceInsights',
          rule_definition: '{"Rules":[]}',
          rule_state: 'ENABLED'
        })
      end

      result = synthesizer.synthesis
      rule = result[:resource][:aws_cloudwatch_insight_rule][:app_perf]

      expect(rule[:name]).to eq('ApplicationPerformanceInsights')
    end

    it 'synthesizes insight rule with tags' do
      pending 'Base.transform_attributes not yet implemented in pangea-core'
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_cloudwatch_insight_rule(:tagged, {
          name: 'TaggedRule',
          rule_definition: '{"Rules":[]}',
          tags: { Environment: 'production', Team: 'platform' }
        })
      end

      result = synthesizer.synthesis
      rule = result[:resource][:aws_cloudwatch_insight_rule][:tagged]

      expect(rule[:tags][:Environment]).to eq('production')
    end
  end

  describe 'resource references' do
    it 'provides correct terraform interpolation strings' do
      pending 'Base.transform_attributes not yet implemented in pangea-core'
      ref = synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_cloudwatch_insight_rule(:test, {
          name: 'TestRule',
          rule_definition: '{"Rules":[]}'
        })
      end

      expect(ref.outputs[:arn]).to eq('${aws_cloudwatch_insight_rule.test.arn}')
    end
  end
end
