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
require 'pangea/resources/aws_ssm_maintenance_window/resource'

RSpec.describe 'aws_ssm_maintenance_window synthesis' do
  let(:synthesizer) { TerraformSynthesizer.new }

  describe 'terraform synthesis' do
    it 'synthesizes basic maintenance window with cron' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_ssm_maintenance_window(:weekly, {
          name: 'weekly-patching',
          schedule: 'cron(0 2 ? * SUN *)',
          duration: 4,
          cutoff: 1
        })
      end

      result = synthesizer.synthesis
      window = result['resource']['aws_ssm_maintenance_window']['weekly']

      expect(window['maintenance_window_name']).to eq('weekly-patching')
      expect(window['schedule']).to eq('cron(0 2 ? * SUN *)')
      expect(window['duration']).to eq(4)
      expect(window['cutoff']).to eq(1)
    end

    it 'synthesizes maintenance window with rate schedule' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_ssm_maintenance_window(:daily, {
          name: 'daily-tasks',
          schedule: 'rate(1 day)',
          duration: 2,
          cutoff: 0
        })
      end

      result = synthesizer.synthesis
      window = result['resource']['aws_ssm_maintenance_window']['daily']

      expect(window['schedule']).to eq('rate(1 day)')
    end

    it 'synthesizes maintenance window with tags' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_ssm_maintenance_window(:tagged, {
          name: 'tagged-window',
          schedule: 'rate(7 days)',
          duration: 3,
          cutoff: 1,
          tags: { Environment: 'production', Purpose: 'patching' }
        })
      end

      result = synthesizer.synthesis
      window = result['resource']['aws_ssm_maintenance_window']['tagged']

      expect(window['tags']['Environment']).to eq('production')
      expect(window['tags']['Purpose']).to eq('patching')
    end

    it 'synthesizes maintenance window with timezone' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_ssm_maintenance_window(:tz_window, {
          name: 'timezone-window',
          schedule: 'cron(0 3 ? * SAT *)',
          duration: 6,
          cutoff: 2,
          schedule_timezone: 'America/New_York'
        })
      end

      result = synthesizer.synthesis
      window = result['resource']['aws_ssm_maintenance_window']['tz_window']

      expect(window['schedule_timezone']).to eq('America/New_York')
    end
  end

  describe 'resource references' do
    it 'returns a ResourceReference with correct outputs' do
      ref = nil
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        ref = aws_ssm_maintenance_window(:test, {
          name: 'test-window',
          schedule: 'rate(1 day)',
          duration: 2,
          cutoff: 0
        })
      end

      expect(ref.outputs[:id]).to eq('${aws_ssm_maintenance_window.test.id}')
      expect(ref.outputs[:arn]).to eq('${aws_ssm_maintenance_window.test.arn}')
      expect(ref.outputs[:name]).to eq('${aws_ssm_maintenance_window.test.name}')
    end
  end

  describe 'validation' do
    it 'rejects cutoff greater than or equal to duration' do
      expect {
        Pangea::Resources::AWS::Types::SsmMaintenanceWindowAttributes.new({
          name: 'test',
          schedule: 'rate(1 day)',
          duration: 3,
          cutoff: 3
        })
      }.to raise_error(Dry::Struct::Error, /Cutoff must be less than duration/)
    end

    it 'rejects invalid schedule expression' do
      expect {
        Pangea::Resources::AWS::Types::SsmMaintenanceWindowAttributes.new({
          name: 'test',
          schedule: 'every tuesday',
          duration: 3,
          cutoff: 1
        })
      }.to raise_error(Dry::Struct::Error, /Schedule must be a cron/)
    end
  end
end
