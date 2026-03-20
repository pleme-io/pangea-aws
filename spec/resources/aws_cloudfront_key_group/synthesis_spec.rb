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
require 'pangea/resources/aws_cloudfront_key_group/resource'

RSpec.describe 'aws_cloudfront_key_group synthesis' do
  let(:synthesizer) { TerraformSynthesizer.new }

  describe 'terraform synthesis' do
    it 'synthesizes with valid attributes' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_cloudfront_key_group(:test, {
          name: 'test-key-group',
          items: ['K3M7YRTR509YPR']
        })
      end

      result = synthesizer.synthesis
      key_group = result[:resource][:aws_cloudfront_key_group][:test]

      expect(key_group[:name]).to eq('test-key-group')
      expect(key_group[:items]).to eq(['K3M7YRTR509YPR'])
    end

    it 'synthesizes with comment' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_cloudfront_key_group(:commented, {
          name: 'commented-key-group',
          items: ['K3M7YRTR509YPR'],
          comment: 'My key group'
        })
      end

      result = synthesizer.synthesis
      key_group = result[:resource][:aws_cloudfront_key_group][:commented]

      expect(key_group[:comment]).to eq('My key group')
    end
  end

  describe 'resource references' do
    it 'returns ResourceReference with correct outputs' do
      ref = synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_cloudfront_key_group(:test, {
          name: 'test-key-group',
          items: ['K3M7YRTR509YPR']
        })
      end

      expect(ref).to be_a(Pangea::Resources::ResourceReference)
      expect(ref.outputs[:id]).to eq('${aws_cloudfront_key_group.test.id}')
      expect(ref.outputs[:etag]).to eq('${aws_cloudfront_key_group.test.etag}')
    end
  end

  describe 'validation' do
    it 'rejects empty items list' do
      expect {
        Pangea::Resources::AWS::Types::CloudFrontKeyGroupAttributes.new(
          name: 'empty-group',
          items: []
        )
      }.to raise_error(Dry::Struct::Error)
    end

    it 'rejects invalid public key ID format' do
      expect {
        Pangea::Resources::AWS::Types::CloudFrontKeyGroupAttributes.new(
          name: 'invalid-keys',
          items: ['not-valid-id']
        )
      }.to raise_error(Dry::Struct::Error)
    end

    it 'rejects duplicate public key IDs' do
      expect {
        Pangea::Resources::AWS::Types::CloudFrontKeyGroupAttributes.new(
          name: 'duplicate-keys',
          items: ['K3M7YRTR509YPR', 'K3M7YRTR509YPR']
        )
      }.to raise_error(Dry::Struct::Error, /duplicate/)
    end
  end
end
