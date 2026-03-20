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
require 'pangea/resources/aws_dynamodb_global_table/resource'

RSpec.describe 'aws_dynamodb_global_table synthesis' do
  let(:synthesizer) { TerraformSynthesizer.new }

  describe 'terraform synthesis' do
    it 'synthesizes basic global table' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_dynamodb_global_table(:basic, {
          name: 'my-global-table',
          replica: [
            { region_name: 'us-east-1' },
            { region_name: 'eu-west-1' }
          ]
        })
      end

      result = synthesizer.synthesis
      gt = result['resource']['aws_dynamodb_global_table']['basic']

      expect(gt['global_table_name']).to eq('my-global-table')
      expect(gt['billing_mode']).to eq('PAY_PER_REQUEST')
    end

    it 'synthesizes global table with stream enabled' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_dynamodb_global_table(:streamed, {
          name: 'streamed-table',
          stream_enabled: true,
          stream_view_type: 'NEW_AND_OLD_IMAGES',
          replica: [
            { region_name: 'us-east-1' },
            { region_name: 'us-west-2' }
          ]
        })
      end

      result = synthesizer.synthesis
      gt = result['resource']['aws_dynamodb_global_table']['streamed']

      expect(gt['stream_enabled']).to be true
      expect(gt['stream_view_type']).to eq('NEW_AND_OLD_IMAGES')
    end
  end

  describe 'resource references' do
    it 'returns ResourceReference with correct outputs' do
      ref = nil
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        ref = aws_dynamodb_global_table(:test, {
          name: 'test-table',
          replica: [
            { region_name: 'us-east-1' },
            { region_name: 'eu-west-1' }
          ]
        })
      end

      expect(ref).to be_a(Pangea::Resources::ResourceReference)
      expect(ref.outputs[:id]).to eq('${aws_dynamodb_global_table.test.id}')
      expect(ref.outputs[:arn]).to eq('${aws_dynamodb_global_table.test.arn}')
      expect(ref.outputs[:global_table_name]).to eq('${aws_dynamodb_global_table.test.global_table_name}')
    end
  end

  describe 'validation' do
    it 'requires at least 2 replicas' do
      expect {
        Pangea::Resources::AWS::Types::DynamoDbGlobalTableAttributes.new(
          name: 'test-table',
          replica: [
            { region_name: 'us-east-1' }
          ]
        )
      }.to raise_error(Dry::Struct::Error)
    end

    it 'rejects duplicate regions' do
      expect {
        Pangea::Resources::AWS::Types::DynamoDbGlobalTableAttributes.new(
          name: 'test-table',
          replica: [
            { region_name: 'us-east-1' },
            { region_name: 'us-east-1' }
          ]
        )
      }.to raise_error(Dry::Struct::Error, /duplicate regions/)
    end

    it 'requires stream_view_type when stream_enabled is true' do
      expect {
        Pangea::Resources::AWS::Types::DynamoDbGlobalTableAttributes.new(
          name: 'test-table',
          stream_enabled: true,
          replica: [
            { region_name: 'us-east-1' },
            { region_name: 'eu-west-1' }
          ]
        )
      }.to raise_error(Dry::Struct::Error, /stream_view_type is required/)
    end

    it 'rejects GSI capacity for PAY_PER_REQUEST billing' do
      expect {
        Pangea::Resources::AWS::Types::DynamoDbGlobalTableAttributes.new(
          name: 'test-table',
          billing_mode: 'PAY_PER_REQUEST',
          replica: [
            {
              region_name: 'us-east-1',
              global_secondary_index: [
                { name: 'gsi-1', read_capacity: 10, write_capacity: 10 }
              ]
            },
            { region_name: 'eu-west-1' }
          ]
        )
      }.to raise_error(Dry::Struct::Error, /should not have capacity settings/)
    end
  end
end
