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
require 'pangea/resources/aws_cloudfront_response_headers_policy/resource'

RSpec.describe 'aws_cloudfront_response_headers_policy synthesis' do
  let(:synthesizer) { TerraformSynthesizer.new }

  describe 'terraform synthesis' do
    it 'synthesizes with security headers' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_cloudfront_response_headers_policy(:test, {
          name: 'test-response-headers',
          security_headers_config: {
            content_type_options: { override: true },
            frame_options: { frame_option: 'DENY', override: true }
          }
        })
      end

      result = synthesizer.synthesis
      policy = result[:resource][:aws_cloudfront_response_headers_policy][:test]

      expect(policy[:name]).to eq('test-response-headers')
    end

    it 'synthesizes with CORS config' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_cloudfront_response_headers_policy(:cors, {
          name: 'cors-policy',
          cors_config: {
            access_control_allow_credentials: false,
            access_control_allow_headers: { items: ['Content-Type'] },
            access_control_allow_methods: { items: ['GET', 'POST'] },
            access_control_allow_origins: { items: ['https://example.com'] },
            origin_override: true
          }
        })
      end

      result = synthesizer.synthesis
      policy = result[:resource][:aws_cloudfront_response_headers_policy][:cors]

      expect(policy[:name]).to eq('cors-policy')
    end
  end

  describe 'resource references' do
    it 'returns ResourceReference with correct outputs' do
      ref = synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_cloudfront_response_headers_policy(:test, {
          name: 'test-policy',
          security_headers_config: {
            content_type_options: { override: true }
          }
        })
      end

      expect(ref).to be_a(Pangea::Resources::ResourceReference)
      expect(ref.outputs[:id]).to eq('${aws_cloudfront_response_headers_policy.test.id}')
      expect(ref.outputs[:etag]).to eq('${aws_cloudfront_response_headers_policy.test.etag}')
    end
  end

  describe 'validation' do
    it 'rejects policy with no configuration' do
      expect {
        Pangea::Resources::AWS::Types::CloudFrontResponseHeadersPolicyAttributes.new(
          name: 'empty-policy'
        )
      }.to raise_error(Dry::Struct::Error, /at least one header configuration/)
    end

    it 'rejects invalid name format' do
      expect {
        Pangea::Resources::AWS::Types::CloudFrontResponseHeadersPolicyAttributes.new(
          name: 'invalid name!',
          security_headers_config: {
            content_type_options: { override: true }
          }
        )
      }.to raise_error(Dry::Struct::Error)
    end
  end
end
