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
require 'pangea/resources/aws_lb_listener_rule/resource'

RSpec.describe 'aws_lb_listener_rule synthesis' do
  let(:synthesizer) { TerraformSynthesizer.new }

  describe 'type validation' do
    it 'accepts valid forward rule with host header condition' do
      attrs = Pangea::Resources::AWS::Types::LoadBalancerListenerRuleAttributes.new(
        listener_arn: '${aws_lb_listener.front_end.arn}',
        priority: 100,
        action: [
          { type: 'forward', target_group_arn: '${aws_lb_target_group.main.arn}' }
        ],
        condition: [
          { host_header: { values: ['example.com'] } }
        ]
      )

      expect(attrs.priority).to eq(100)
      expect(attrs.action.length).to eq(1)
      expect(attrs.condition.length).to eq(1)
    end

    it 'accepts tags' do
      attrs = Pangea::Resources::AWS::Types::LoadBalancerListenerRuleAttributes.new(
        listener_arn: '${aws_lb_listener.front_end.arn}',
        priority: 200,
        action: [
          { type: 'forward', target_group_arn: '${aws_lb_target_group.main.arn}' }
        ],
        condition: [
          { path_pattern: { values: ['/api/*'] } }
        ],
        tags: { Environment: 'production' }
      )

      expect(attrs.tags[:Environment]).to eq('production')
    end
  end

  describe 'validation' do
    it 'rejects priority outside valid range' do
      expect {
        Pangea::Resources::AWS::Types::LoadBalancerListenerRuleAttributes.new(
          listener_arn: '${aws_lb_listener.front_end.arn}',
          priority: 50001,
          action: [{ type: 'forward', target_group_arn: 'arn:test' }],
          condition: [{ host_header: { values: ['example.com'] } }]
        )
      }.to raise_error(Dry::Struct::Error)
    end

    it 'rejects condition with no condition type' do
      expect {
        Pangea::Resources::AWS::Types::LoadBalancerListenerRuleAttributes.new(
          listener_arn: '${aws_lb_listener.front_end.arn}',
          priority: 100,
          action: [{ type: 'forward', target_group_arn: 'arn:test' }],
          condition: [{}]
        )
      }.to raise_error(Dry::Struct::Error, /condition type/)
    end

    it 'rejects empty action list' do
      expect {
        Pangea::Resources::AWS::Types::LoadBalancerListenerRuleAttributes.new(
          listener_arn: '${aws_lb_listener.front_end.arn}',
          priority: 100,
          action: [],
          condition: [{ host_header: { values: ['example.com'] } }]
        )
      }.to raise_error(Dry::Struct::Error)
    end

    it 'rejects empty condition list' do
      expect {
        Pangea::Resources::AWS::Types::LoadBalancerListenerRuleAttributes.new(
          listener_arn: '${aws_lb_listener.front_end.arn}',
          priority: 100,
          action: [{ type: 'forward', target_group_arn: 'arn:test' }],
          condition: []
        )
      }.to raise_error(Dry::Struct::Error)
    end
  end
end
