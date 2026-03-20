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
require 'pangea/resources/aws_rds_cluster_endpoint/resource'

RSpec.describe 'aws_rds_cluster_endpoint synthesis' do
  let(:synthesizer) { TerraformSynthesizer.new }

  describe 'terraform synthesis' do
    it 'synthesizes basic cluster endpoint' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_rds_cluster_endpoint(:reader, {
          cluster_identifier: 'my-aurora-cluster',
          cluster_endpoint_identifier: 'reader-endpoint',
          custom_endpoint_type: 'READER'
        })
      end

      result = synthesizer.synthesis
      endpoint = result['resource']['aws_rds_cluster_endpoint']['reader']

      expect(endpoint['cluster_identifier']).to eq('my-aurora-cluster')
      expect(endpoint['cluster_endpoint_identifier']).to eq('reader-endpoint')
      expect(endpoint['custom_endpoint_type']).to eq('READER')
    end

    it 'synthesizes cluster endpoint with tags' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_rds_cluster_endpoint(:tagged, {
          cluster_identifier: 'my-cluster',
          cluster_endpoint_identifier: 'analytics-endpoint',
          custom_endpoint_type: 'READER',
          tags: { Purpose: 'analytics', Environment: 'production' }
        })
      end

      result = synthesizer.synthesis
      endpoint = result['resource']['aws_rds_cluster_endpoint']['tagged']

      expect(endpoint['tags']['Purpose']).to eq('analytics')
      expect(endpoint['tags']['Environment']).to eq('production')
    end
  end

  describe 'resource references' do
    it 'returns a ResourceReference with correct outputs' do
      ref = nil
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        ref = aws_rds_cluster_endpoint(:test, {
          cluster_identifier: 'test-cluster',
          cluster_endpoint_identifier: 'test-endpoint',
          custom_endpoint_type: 'READER'
        })
      end

      expect(ref.outputs[:id]).to eq('${aws_rds_cluster_endpoint.test.id}')
      expect(ref.outputs[:arn]).to eq('${aws_rds_cluster_endpoint.test.arn}')
      expect(ref.outputs[:endpoint]).to eq('${aws_rds_cluster_endpoint.test.endpoint}')
    end
  end

  describe 'validation' do
    it 'rejects invalid endpoint identifier format' do
      expect {
        Pangea::Resources::AWS::Types::RdsClusterEndpointAttributes.new({
          cluster_identifier: 'test-cluster',
          cluster_endpoint_identifier: '123-starts-with-number',
          custom_endpoint_type: 'READER'
        })
      }.to raise_error(Dry::Struct::Error, /must start with a letter/)
    end
  end
end
