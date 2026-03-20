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
require 'pangea/resources/aws_s3_bucket_notification/resource'

RSpec.describe 'aws_s3_bucket_notification synthesis' do
  let(:synthesizer) { TerraformSynthesizer.new }

  describe 'terraform synthesis' do
    it 'synthesizes Lambda notification' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_s3_bucket_notification(:lambda_notif, {
          bucket: 'my-bucket',
          cloudwatch_configuration: [],
          queue: [],
          lambda_function: [
            {
              lambda_function_arn: 'arn:aws:lambda:us-east-1:123456789012:function:process',
              events: ['s3:ObjectCreated:*']
            }
          ]
        })
      end

      result = synthesizer.synthesis
      notif = result['resource']['aws_s3_bucket_notification']['lambda_notif']

      expect(notif['bucket']).to eq('my-bucket')
    end

    it 'synthesizes SQS notification' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_s3_bucket_notification(:sqs_notif, {
          bucket: 'my-bucket',
          cloudwatch_configuration: [],
          lambda_function: [],
          queue: [
            {
              queue_arn: 'arn:aws:sqs:us-east-1:123456789012:my-queue',
              events: ['s3:ObjectCreated:*']
            }
          ]
        })
      end

      result = synthesizer.synthesis
      notif = result['resource']['aws_s3_bucket_notification']['sqs_notif']

      expect(notif['bucket']).to eq('my-bucket')
    end

    it 'synthesizes EventBridge notification' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_s3_bucket_notification(:eb_notif, {
          bucket: 'my-bucket',
          cloudwatch_configuration: [],
          lambda_function: [],
          queue: [],
          eventbridge: true
        })
      end

      result = synthesizer.synthesis
      notif = result['resource']['aws_s3_bucket_notification']['eb_notif']

      expect(notif['bucket']).to eq('my-bucket')
      expect(notif['eventbridge']).to be true
    end
  end

  describe 'resource references' do
    it 'returns ResourceReference with correct outputs' do
      ref = nil
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        ref = aws_s3_bucket_notification(:test, {
          bucket: 'test-bucket',
          cloudwatch_configuration: [],
          lambda_function: [],
          queue: [],
          eventbridge: true
        })
      end

      expect(ref).to be_a(Pangea::Resources::ResourceReference)
      expect(ref.outputs[:id]).to eq('${aws_s3_bucket_notification.test.id}')
      expect(ref.outputs[:bucket]).to eq('${aws_s3_bucket_notification.test.bucket}')
    end
  end

  describe 'validation' do
    it 'requires at least one notification configuration' do
      expect {
        Pangea::Resources::AWS::Types::S3BucketNotificationAttributes.new(
          bucket: 'test',
          cloudwatch_configuration: [],
          lambda_function: [],
          queue: [],
          eventbridge: false
        )
      }.to raise_error(Dry::Struct::Error, /At least one notification configuration/)
    end

    it 'validates Lambda ARN format' do
      expect {
        Pangea::Resources::AWS::Types::S3BucketNotificationAttributes.new(
          bucket: 'test',
          cloudwatch_configuration: [],
          queue: [],
          lambda_function: [
            {
              lambda_function_arn: 'invalid-arn',
              events: ['s3:ObjectCreated:*']
            }
          ]
        )
      }.to raise_error(Dry::Struct::Error, /LAMBDA ARN/)
    end

    it 'validates SQS ARN format' do
      expect {
        Pangea::Resources::AWS::Types::S3BucketNotificationAttributes.new(
          bucket: 'test',
          cloudwatch_configuration: [],
          lambda_function: [],
          queue: [
            {
              queue_arn: 'invalid-arn',
              events: ['s3:ObjectCreated:*']
            }
          ]
        )
      }.to raise_error(Dry::Struct::Error, /SQS ARN/)
    end
  end
end
