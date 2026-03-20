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
require 'pangea/resources/aws_route53_delegation_set/resource'

RSpec.describe 'aws_route53_delegation_set synthesis' do
  let(:synthesizer) { TerraformSynthesizer.new }

  describe 'terraform synthesis' do
    it 'synthesizes with reference name' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_route53_delegation_set(:test, {
          reference_name: 'my-delegation-set'
        })
      end

      result = synthesizer.synthesis
      delegation_set = result[:resource][:aws_route53_delegation_set][:test]

      expect(delegation_set[:reference_name]).to eq('my-delegation-set')
    end

    it 'synthesizes with tags' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_route53_delegation_set(:tagged, {
          reference_name: 'tagged-delegation',
          tags: { Environment: 'production' }
        })
      end

      result = synthesizer.synthesis
      delegation_set = result[:resource][:aws_route53_delegation_set][:tagged]

      expect(delegation_set[:tags][:Environment]).to eq('production')
    end
  end

  describe 'resource references' do
    it 'returns ResourceReference with correct outputs' do
      ref = synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_route53_delegation_set(:test, {
          reference_name: 'test-delegation'
        })
      end

      expect(ref).to be_a(Pangea::Resources::ResourceReference)
      expect(ref.outputs[:id]).to eq('${aws_route53_delegation_set.test.id}')
      expect(ref.outputs[:arn]).to eq('${aws_route53_delegation_set.test.arn}')
      expect(ref.outputs[:name_servers]).to eq('${aws_route53_delegation_set.test.name_servers}')
    end
  end

  describe 'validation' do
    it 'rejects invalid reference name format' do
      expect {
        Pangea::Resources::AWS::Types::Route53DelegationSetAttributes.new(
          reference_name: 'invalid name with spaces!'
        )
      }.to raise_error(Dry::Struct::Error)
    end
  end
end
