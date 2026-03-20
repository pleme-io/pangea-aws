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
require 'pangea/resources/aws_s3_object_lambda_access_point/resource'

RSpec.describe 'aws_s3_object_lambda_access_point synthesis' do
  let(:attrs_class) { Pangea::Resources::AWS::S3ObjectLambdaAccessPoint::S3ObjectLambdaAccessPointAttributes }
  let(:supporting_ap_arn) { 'arn:aws:s3:us-east-1:123456789012:accesspoint/supporting-ap' }
  let(:lambda_arn) { 'arn:aws:lambda:us-east-1:123456789012:function:transform-fn' }

  describe 'type validation' do
    it 'creates valid object lambda access point' do
      attrs = attrs_class.new(
        name: 'test-olap',
        configuration: {
          supporting_access_point: supporting_ap_arn,
          transformation_configuration: [
            {
              actions: ['GetObject'],
              content_transformation: {
                aws_lambda: { function_arn: lambda_arn }
              }
            }
          ]
        }
      )

      expect(attrs.transformation_count).to eq(1)
      expect(attrs.lambda_functions).to eq([lambda_arn])
      expect(attrs.supported_actions).to eq(['GetObject'])
      expect(attrs.has_payload?).to be false
      expect(attrs.supporting_access_point).to eq(supporting_ap_arn)
    end

    it 'detects payload configuration' do
      attrs = attrs_class.new(
        name: 'test-olap',
        configuration: {
          supporting_access_point: supporting_ap_arn,
          transformation_configuration: [
            {
              actions: ['GetObject'],
              content_transformation: {
                aws_lambda: {
                  function_arn: lambda_arn,
                  function_payload: '{"flag": true}'
                }
              }
            }
          ]
        }
      )

      expect(attrs.has_payload?).to be true
    end

    it 'supports multiple transformations' do
      lambda_arn_2 = 'arn:aws:lambda:us-east-1:123456789012:function:list-fn'
      attrs = attrs_class.new(
        name: 'multi-olap',
        configuration: {
          supporting_access_point: supporting_ap_arn,
          transformation_configuration: [
            {
              actions: ['GetObject'],
              content_transformation: {
                aws_lambda: { function_arn: lambda_arn }
              }
            },
            {
              actions: ['ListObjects'],
              content_transformation: {
                aws_lambda: { function_arn: lambda_arn_2 }
              }
            }
          ]
        }
      )

      expect(attrs.transformation_count).to eq(2)
      expect(attrs.supported_actions).to contain_exactly('GetObject', 'ListObjects')
    end
  end

  describe 'validation' do
    it 'accepts valid configuration with transformations' do
      expect {
        attrs_class.new(
          name: 'valid-olap',
          configuration: {
            supporting_access_point: supporting_ap_arn,
            transformation_configuration: [
              {
                actions: ['GetObject'],
                content_transformation: {
                  aws_lambda: { function_arn: lambda_arn }
                }
              }
            ]
          }
        )
      }.not_to raise_error
    end

    it 'rejects invalid access point name' do
      expect {
        attrs_class.new(
          name: 'INVALID_NAME',
          configuration: {
            supporting_access_point: supporting_ap_arn,
            transformation_configuration: [
              {
                actions: ['GetObject'],
                content_transformation: {
                  aws_lambda: { function_arn: lambda_arn }
                }
              }
            ]
          }
        )
      }.to raise_error(Dry::Struct::Error)
    end
  end
end
