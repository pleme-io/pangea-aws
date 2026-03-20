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
require 'pangea/resources/aws_cloudwatch_log_data_protection_policy/resource'

RSpec.describe 'aws_cloudwatch_log_data_protection_policy synthesis' do
  let(:synthesizer) { TerraformSynthesizer.new }

  describe 'terraform synthesis' do
    it 'synthesizes basic data protection policy' do
      pending 'Base.transform_attributes not yet implemented in pangea-core'
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_cloudwatch_log_data_protection_policy(:pii_protection, {
          log_group_name: '/aws/lambda/my-function',
          policy_document: '{"Name":"PIIPolicy","Version":"2021-06-01","Statement":[]}'
        })
      end

      result = synthesizer.synthesis
      policy = result[:resource][:aws_cloudwatch_log_data_protection_policy][:pii_protection]

      expect(policy[:log_group_name]).to eq('/aws/lambda/my-function')
    end
  end

  describe 'resource references' do
    it 'provides correct terraform interpolation strings' do
      pending 'Base.transform_attributes not yet implemented in pangea-core'
      ref = synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_cloudwatch_log_data_protection_policy(:test, {
          log_group_name: '/test/group',
          policy_document: '{"Name":"Test","Version":"2021-06-01","Statement":[]}'
        })
      end

      expect(ref.outputs[:id]).to eq('${aws_cloudwatch_log_data_protection_policy.test.id}')
    end
  end
end
