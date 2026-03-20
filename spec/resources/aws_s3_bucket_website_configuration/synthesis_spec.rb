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
require 'pangea/resources/aws_s3_bucket_website_configuration/resource'

RSpec.describe 'aws_s3_bucket_website_configuration synthesis' do
  let(:synthesizer) { TerraformSynthesizer.new }

  describe 'terraform synthesis' do
    it 'synthesizes website hosting configuration' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_s3_bucket_website_configuration(:site, {
          bucket: 'my-site-bucket',
          index_document: { suffix: 'index.html' },
          error_document: { key: 'error.html' }
        })
      end

      result = synthesizer.synthesis
      site = result['resource']['aws_s3_bucket_website_configuration']['site']

      expect(site['bucket']).to eq('my-site-bucket')
    end

    it 'synthesizes redirect all requests' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_s3_bucket_website_configuration(:redirect, {
          bucket: 'redirect-bucket',
          redirect_all_requests_to: {
            host_name: 'www.example.com',
            protocol: 'https'
          }
        })
      end

      result = synthesizer.synthesis
      site = result['resource']['aws_s3_bucket_website_configuration']['redirect']

      expect(site['bucket']).to eq('redirect-bucket')
    end
  end

  describe 'resource references' do
    it 'returns ResourceReference with correct outputs' do
      ref = nil
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        ref = aws_s3_bucket_website_configuration(:test, {
          bucket: 'test-bucket',
          index_document: { suffix: 'index.html' }
        })
      end

      expect(ref).to be_a(Pangea::Resources::ResourceReference)
      expect(ref.outputs[:id]).to eq('${aws_s3_bucket_website_configuration.test.id}')
      expect(ref.outputs[:bucket]).to eq('${aws_s3_bucket_website_configuration.test.bucket}')
      expect(ref.outputs[:website_domain]).to eq('${aws_s3_bucket_website_configuration.test.website_domain}')
      expect(ref.outputs[:website_endpoint]).to eq('${aws_s3_bucket_website_configuration.test.website_endpoint}')
    end
  end

  describe 'validation' do
    it 'rejects both website hosting and redirect_all_requests_to' do
      expect {
        Pangea::Resources::AWS::Types::S3BucketWebsiteConfigurationAttributes.new(
          bucket: 'test',
          index_document: { suffix: 'index.html' },
          redirect_all_requests_to: { host_name: 'example.com' }
        )
      }.to raise_error(Dry::Struct::Error, /Cannot specify both/)
    end

    it 'requires either website config or redirect' do
      expect {
        Pangea::Resources::AWS::Types::S3BucketWebsiteConfigurationAttributes.new(
          bucket: 'test'
        )
      }.to raise_error(Dry::Struct::Error, /Must specify either/)
    end

    it 'requires index_document for website hosting mode' do
      expect {
        Pangea::Resources::AWS::Types::S3BucketWebsiteConfigurationAttributes.new(
          bucket: 'test',
          error_document: { key: 'error.html' }
        )
      }.to raise_error(Dry::Struct::Error, /index_document is required/)
    end
  end
end
