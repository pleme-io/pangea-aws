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
require 'pangea/resources/aws_s3_object/resource'

RSpec.describe 'aws_s3_object synthesis' do
  let(:synthesizer) { TerraformSynthesizer.new }

  describe 'terraform synthesis' do
    it 'synthesizes S3 object with inline content' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_s3_object(:inline, {
          bucket: 'my-bucket',
          key: 'config.json',
          content: '{"key": "value"}'
        })
      end

      result = synthesizer.synthesis
      obj = result['resource']['aws_s3_object']['inline']

      expect(obj['bucket']).to eq('my-bucket')
      expect(obj['key']).to eq('config.json')
      expect(obj['content']).to eq('{"key": "value"}')
    end

    it 'synthesizes S3 object with source file' do
      # Create a temp file
      require 'tempfile'
      tmpfile = Tempfile.new(['test', '.html'])
      tmpfile.write('<html></html>')
      tmpfile.close

      src = tmpfile.path
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_s3_object(:file_upload, {
          bucket: 'my-bucket',
          key: 'index.html',
          source: src
        })
      end

      result = synthesizer.synthesis
      obj = result['resource']['aws_s3_object']['file_upload']

      expect(obj['bucket']).to eq('my-bucket')
      expect(obj['key']).to eq('index.html')

      tmpfile.unlink
    end
  end

  describe 'resource references' do
    it 'returns ResourceReference with correct outputs' do
      ref = nil
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        ref = aws_s3_object(:test, {
          bucket: 'test-bucket',
          key: 'test-key',
          content: 'test'
        })
      end

      expect(ref).to be_a(Pangea::Resources::ResourceReference)
      expect(ref.outputs[:id]).to eq('${aws_s3_object.test.id}')
      expect(ref.outputs[:bucket]).to eq('${aws_s3_object.test.bucket}')
      expect(ref.outputs[:key]).to eq('${aws_s3_object.test.key}')
      expect(ref.outputs[:etag]).to eq('${aws_s3_object.test.etag}')
    end
  end

  describe 'validation' do
    it 'requires either source or content' do
      expect {
        Pangea::Resources::AWS::Types::S3ObjectAttributes.new(
          bucket: 'test',
          key: 'test-key'
        )
      }.to raise_error(Dry::Struct::Error, /either source or content must be specified/)
    end

    it 'rejects both source and content' do
      require 'tempfile'
      tmpfile = Tempfile.new(['test', '.txt'])
      tmpfile.write('data')
      tmpfile.close

      expect {
        Pangea::Resources::AWS::Types::S3ObjectAttributes.new(
          bucket: 'test',
          key: 'test-key',
          source: tmpfile.path,
          content: 'inline-content'
        )
      }.to raise_error(Dry::Struct::Error, /mutually exclusive/)

      tmpfile.unlink
    end

    it 'requires kms_key_id for aws:kms encryption' do
      expect {
        Pangea::Resources::AWS::Types::S3ObjectAttributes.new(
          bucket: 'test',
          key: 'test-key',
          content: 'data',
          server_side_encryption: 'aws:kms'
        )
      }.to raise_error(Dry::Struct::Error, /kms_key_id is required/)
    end

    it 'requires retain_until_date when object_lock_mode set' do
      expect {
        Pangea::Resources::AWS::Types::S3ObjectAttributes.new(
          bucket: 'test',
          key: 'test-key',
          content: 'data',
          object_lock_mode: 'GOVERNANCE'
        )
      }.to raise_error(Dry::Struct::Error, /object_lock_retain_until_date is required/)
    end
  end
end
