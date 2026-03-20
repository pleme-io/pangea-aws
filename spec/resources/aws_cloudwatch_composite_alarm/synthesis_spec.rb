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
require 'pangea/resources/aws_cloudwatch_composite_alarm/resource'

RSpec.describe 'aws_cloudwatch_composite_alarm synthesis' do
  let(:synthesizer) { TerraformSynthesizer.new }

  describe 'terraform synthesis' do
    it 'synthesizes basic composite alarm' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_cloudwatch_composite_alarm(:critical, {
          alarm_name: 'critical-failures',
          alarm_rule: 'ALARM(high-cpu) AND ALARM(high-memory)'
        })
      end

      result = synthesizer.synthesis
      alarm = result['resource']['aws_cloudwatch_composite_alarm']['critical']

      expect(alarm['alarm_name']).to eq('critical-failures')
      expect(alarm['alarm_rule']).to eq('ALARM(high-cpu) AND ALARM(high-memory)')
    end

    it 'synthesizes composite alarm with actions' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_cloudwatch_composite_alarm(:with_actions, {
          alarm_name: 'with-actions',
          alarm_rule: 'ALARM(api-errors) OR ALARM(db-errors)',
          alarm_actions: ['arn:aws:sns:us-east-1:123456789012:alerts'],
          ok_actions: ['arn:aws:sns:us-east-1:123456789012:recovery']
        })
      end

      result = synthesizer.synthesis
      alarm = result['resource']['aws_cloudwatch_composite_alarm']['with_actions']

      expect(alarm['alarm_actions']).to include('arn:aws:sns:us-east-1:123456789012:alerts')
      expect(alarm['ok_actions']).to include('arn:aws:sns:us-east-1:123456789012:recovery')
    end

    it 'synthesizes composite alarm with tags' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_cloudwatch_composite_alarm(:tagged, {
          alarm_name: 'tagged-alarm',
          alarm_rule: 'ALARM(test-alarm)',
          tags: { Environment: 'production' }
        })
      end

      result = synthesizer.synthesis
      alarm = result['resource']['aws_cloudwatch_composite_alarm']['tagged']

      expect(alarm['tags']['Environment']).to eq('production')
    end
  end

  describe 'resource references' do
    it 'returns a ResourceReference with correct outputs' do
      ref = nil
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        ref = aws_cloudwatch_composite_alarm(:test, {
          alarm_name: 'test-composite',
          alarm_rule: 'ALARM(test-alarm)'
        })
      end

      expect(ref.outputs[:id]).to eq('${aws_cloudwatch_composite_alarm.test.id}')
      expect(ref.outputs[:arn]).to eq('${aws_cloudwatch_composite_alarm.test.arn}')
    end
  end

  describe 'validation' do
    it 'rejects invalid alarm rule without valid operators' do
      expect {
        Pangea::Resources::AWS::Types::CloudWatchCompositeAlarmAttributes.new({
          alarm_name: 'test',
          alarm_rule: 'invalid rule without operators'
        })
      }.to raise_error(Dry::Struct::Error, /alarm_rule must contain valid/)
    end

    it 'rejects alarm rule with mismatched parentheses' do
      expect {
        Pangea::Resources::AWS::Types::CloudWatchCompositeAlarmAttributes.new({
          alarm_name: 'test',
          alarm_rule: 'ALARM(high-cpu AND ALARM(high-memory)'
        })
      }.to raise_error(Dry::Struct::Error, /mismatched parentheses/)
    end
  end
end
