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
require 'pangea/resources/aws_cloudfront_public_key/resource'

RSpec.describe 'aws_cloudfront_public_key synthesis' do
  let(:synthesizer) { TerraformSynthesizer.new }

  let(:sample_pem_key) do
    <<~PEM
      -----BEGIN PUBLIC KEY-----
      MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA0Z3VS5JJcds3xfn/ygWe
      GOfas4E9kReZm5G1U2B6PGH6KW8NDVX2h+TiZsJmYj5Ax6oCyIhNqAjg6cLpGUj
      VccFEcXHA+mVRpbQJEOmhfCZU5hULDpLyv54IkTGS3CxPaVj0GE4OGR3ZJf8aBxL
      VYqhWKFbcFBMa49ToOxnEjwBOTb8JR1AQQHU/UJpW7j0/GXJfS/3DW1iX9y0A87p
      nKvBiw6E4LR+kpZeJAl3VvD/MnJ8C2OyHqpJfJOq+T0Y0F2MK3m3DsHPUfLwPMh
      2r0M7hzC/dI8IM9sMMb+ppdwHI/yCINv4UMjuYw8q6MaRs3JqVEkiiiKWQ2hqvkL
      rwIDAQAB
      -----END PUBLIC KEY-----
    PEM
  end

  describe 'type validation' do
    it 'accepts valid attributes' do
      attrs = Pangea::Resources::AWS::Types::CloudFrontPublicKeyAttributes.new(
        name: 'test-public-key',
        encoded_key: sample_pem_key
      )

      expect(attrs.name).to eq('test-public-key')
      expect(attrs.valid_public_key_format?).to be true
    end

    it 'sets default comment when not provided' do
      attrs = Pangea::Resources::AWS::Types::CloudFrontPublicKeyAttributes.new(
        name: 'test-key',
        encoded_key: sample_pem_key
      )

      expect(attrs.comment).to include('test-key')
    end

    it 'provides key size information' do
      attrs = Pangea::Resources::AWS::Types::CloudFrontPublicKeyAttributes.new(
        name: 'test-key',
        encoded_key: sample_pem_key
      )

      expect(attrs.key_size).to be_a(String)
      expect(attrs.key_type).to eq('RSA')
    end
  end

  describe 'validation' do
    it 'rejects invalid key format' do
      expect {
        Pangea::Resources::AWS::Types::CloudFrontPublicKeyAttributes.new(
          name: 'bad-key',
          encoded_key: 'not-a-pem-key'
        )
      }.to raise_error(Dry::Struct::Error)
    end

    it 'rejects invalid name format' do
      expect {
        Pangea::Resources::AWS::Types::CloudFrontPublicKeyAttributes.new(
          name: 'invalid name with spaces!',
          encoded_key: sample_pem_key
        )
      }.to raise_error(Dry::Struct::Error)
    end
  end
end
