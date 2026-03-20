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
require 'pangea/resources/aws_ssm_patch_baseline/resource'

RSpec.describe 'aws_ssm_patch_baseline synthesis' do
  let(:synthesizer) { TerraformSynthesizer.new }

  describe 'terraform synthesis' do
    it 'synthesizes basic patch baseline' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_ssm_patch_baseline(:amazon_linux, {
          name: 'amazon-linux-baseline',
          operating_system: 'AMAZON_LINUX_2'
        })
      end

      result = synthesizer.synthesis
      baseline = result['resource']['aws_ssm_patch_baseline']['amazon_linux']

      expect(baseline['patch_baseline_name']).to eq('amazon-linux-baseline')
      expect(baseline['operating_system']).to eq('AMAZON_LINUX_2')
    end

    it 'synthesizes patch baseline with approval rules' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_ssm_patch_baseline(:with_rules, {
          name: 'windows-baseline',
          operating_system: 'WINDOWS',
          approval_rule: [{
            approve_after_days: 7,
            compliance_level: 'HIGH',
            patch_filter: [{
              key: 'CLASSIFICATION',
              values: ['CriticalUpdates', 'SecurityUpdates']
            }]
          }]
        })
      end

      result = synthesizer.synthesis
      baseline = result['resource']['aws_ssm_patch_baseline']['with_rules']

      expect(baseline).to have_key('approval_rule')
    end

    it 'synthesizes patch baseline with tags' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_ssm_patch_baseline(:tagged, {
          name: 'tagged-baseline',
          operating_system: 'UBUNTU',
          tags: { Environment: 'production', ManagedBy: 'terraform' }
        })
      end

      result = synthesizer.synthesis
      baseline = result['resource']['aws_ssm_patch_baseline']['tagged']

      expect(baseline['tags']['Environment']).to eq('production')
      expect(baseline['tags']['ManagedBy']).to eq('terraform')
    end

    it 'synthesizes patch baseline with approved and rejected patches' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_ssm_patch_baseline(:explicit, {
          name: 'explicit-baseline',
          operating_system: 'AMAZON_LINUX_2',
          approved_patches: ['KB123456'],
          rejected_patches: ['KB654321'],
          approved_patches_compliance_level: 'CRITICAL'
        })
      end

      result = synthesizer.synthesis
      baseline = result['resource']['aws_ssm_patch_baseline']['explicit']

      expect(baseline['approved_patches']).to include('KB123456')
      expect(baseline['rejected_patches']).to include('KB654321')
      expect(baseline['approved_patches_compliance_level']).to eq('CRITICAL')
    end
  end

  describe 'resource references' do
    it 'returns a ResourceReference with correct outputs' do
      ref = nil
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        ref = aws_ssm_patch_baseline(:test, {
          name: 'test-baseline',
          operating_system: 'AMAZON_LINUX_2'
        })
      end

      expect(ref.outputs[:id]).to eq('${aws_ssm_patch_baseline.test.id}')
      expect(ref.outputs[:arn]).to eq('${aws_ssm_patch_baseline.test.arn}')
      expect(ref.outputs[:name]).to eq('${aws_ssm_patch_baseline.test.name}')
      expect(ref.outputs[:operating_system]).to eq('${aws_ssm_patch_baseline.test.operating_system}')
    end
  end
end
