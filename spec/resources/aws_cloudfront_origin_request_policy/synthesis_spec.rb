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
require 'pangea/resources/aws_cloudfront_origin_request_policy/resource'

RSpec.describe 'aws_cloudfront_origin_request_policy synthesis' do
  describe 'type validation' do
    it 'accepts valid attributes with defaults' do
      attrs = Pangea::Resources::AWS::CloudFrontOriginRequestPolicyAttributes.new(
        name: 'test-origin-request-policy'
      )

      expect(attrs.name).to eq('test-origin-request-policy')
      expect(attrs.headers_config[:header_behavior]).to eq('none')
      expect(attrs.query_strings_config[:query_string_behavior]).to eq('none')
      expect(attrs.cookies_config[:cookie_behavior]).to eq('none')
    end

    it 'accepts header whitelisting' do
      attrs = Pangea::Resources::AWS::CloudFrontOriginRequestPolicyAttributes.new(
        name: 'headers-policy',
        headers_config: {
          header_behavior: 'whitelist',
          headers: { items: ['Authorization', 'Accept'] }
        },
        query_strings_config: { query_string_behavior: 'all' },
        cookies_config: { cookie_behavior: 'none' }
      )

      expect(attrs.headers_config[:header_behavior]).to eq('whitelist')
    end

    it 'rejects invalid header behavior' do
      expect {
        Pangea::Resources::AWS::CloudFrontOriginRequestPolicyAttributes.new(
          name: 'bad-policy',
          headers_config: { header_behavior: 'invalid' }
        )
      }.to raise_error(Dry::Struct::Error)
    end
  end
end
