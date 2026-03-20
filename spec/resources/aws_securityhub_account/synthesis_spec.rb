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
require 'pangea/resources/aws_securityhub_account/resource'

RSpec.describe 'aws_securityhub_account synthesis' do
  let(:synthesizer) { TerraformSynthesizer.new }

  describe 'terraform synthesis' do
    it 'synthesizes with default attributes' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_securityhub_account(:test, {})
      end

      result = synthesizer.synthesis
      account = result[:resource][:aws_securityhub_account][:test]

      expect(account[:enable_default_standards]).to eq(true)
      expect(account[:auto_enable_controls]).to eq(true)
      expect(account[:control_finding_generator]).to eq('STANDARD_CONTROL')
    end

    it 'synthesizes with custom configuration' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_securityhub_account(:custom, {
          enable_default_standards: false,
          control_finding_generator: 'SECURITY_CONTROL',
          auto_enable_controls: false
        })
      end

      result = synthesizer.synthesis
      account = result[:resource][:aws_securityhub_account][:custom]

      expect(account[:enable_default_standards]).to eq(false)
      expect(account[:control_finding_generator]).to eq('SECURITY_CONTROL')
      expect(account[:auto_enable_controls]).to eq(false)
    end

    it 'synthesizes with tags' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_securityhub_account(:tagged, {
          tags: { Environment: 'production' }
        })
      end

      result = synthesizer.synthesis
      account = result[:resource][:aws_securityhub_account][:tagged]

      expect(account[:tags][:Environment]).to eq('production')
    end
  end

  describe 'resource references' do
    it 'returns ResourceReference with correct outputs' do
      ref = synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_securityhub_account(:test, {})
      end

      expect(ref).to be_a(Pangea::Resources::ResourceReference)
      expect(ref.outputs[:id]).to eq('${aws_securityhub_account.test.id}')
      expect(ref.outputs[:arn]).to eq('${aws_securityhub_account.test.arn}')
    end
  end

  describe 'validation' do
    it 'rejects invalid control_finding_generator value' do
      expect {
        Pangea::Resources::AWS::Types::SecurityHubAccountAttributes.new(
          control_finding_generator: 'INVALID_VALUE'
        )
      }.to raise_error(Dry::Struct::Error)
    end
  end
end
