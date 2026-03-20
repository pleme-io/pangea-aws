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
require 'pangea/resources/aws_rds_global_cluster/resource'

RSpec.describe 'aws_rds_global_cluster synthesis' do
  let(:synthesizer) { TerraformSynthesizer.new }

  describe 'terraform synthesis' do
    it 'synthesizes basic global cluster' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_rds_global_cluster(:global, {
          global_cluster_identifier: 'global-aurora-mysql',
          engine: 'aurora-mysql',
          master_username: 'admin'
        })
      end

      result = synthesizer.synthesis
      cluster = result['resource']['aws_rds_global_cluster']['global']

      expect(cluster['global_cluster_identifier']).to eq('global-aurora-mysql')
      expect(cluster['engine']).to eq('aurora-mysql')
      expect(cluster['storage_encrypted']).to eq(true)
    end

    it 'synthesizes global cluster with tags' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_rds_global_cluster(:tagged, {
          global_cluster_identifier: 'tagged-global',
          engine: 'aurora-postgresql',
          master_username: 'admin',
          tags: { Environment: 'production', Team: 'platform' }
        })
      end

      result = synthesizer.synthesis
      cluster = result['resource']['aws_rds_global_cluster']['tagged']

      expect(cluster['tags']['Environment']).to eq('production')
    end

    it 'synthesizes global cluster from source' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_rds_global_cluster(:from_source, {
          global_cluster_identifier: 'from-source',
          engine: 'aurora-mysql',
          source_db_cluster_identifier: 'arn:aws:rds:us-east-1:123456789012:cluster:source-cluster'
        })
      end

      result = synthesizer.synthesis
      cluster = result['resource']['aws_rds_global_cluster']['from_source']

      expect(cluster['source_db_cluster_identifier']).to include('source-cluster')
    end
  end

  describe 'resource references' do
    it 'returns a ResourceReference with correct outputs' do
      ref = nil
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        ref = aws_rds_global_cluster(:test, {
          global_cluster_identifier: 'test-global',
          engine: 'aurora-mysql',
          master_username: 'admin'
        })
      end

      expect(ref.outputs[:id]).to eq('${aws_rds_global_cluster.test.id}')
      expect(ref.outputs[:arn]).to eq('${aws_rds_global_cluster.test.arn}')
      expect(ref.outputs[:global_cluster_identifier]).to eq('${aws_rds_global_cluster.test.global_cluster_identifier}')
    end
  end

  describe 'validation' do
    it 'rejects both master_password and manage_master_user_password' do
      expect {
        Pangea::Resources::AWS::Types::RdsGlobalClusterAttributes.new({
          global_cluster_identifier: 'test',
          engine: 'aurora-mysql',
          master_username: 'admin',
          master_password: 'secret123',
          manage_master_user_password: true
        })
      }.to raise_error(Dry::Struct::Error, /Cannot specify both/)
    end

    it 'rejects missing master_username when no source cluster' do
      expect {
        Pangea::Resources::AWS::Types::RdsGlobalClusterAttributes.new({
          global_cluster_identifier: 'test',
          engine: 'aurora-mysql',
          manage_master_user_password: false
        })
      }.to raise_error(Dry::Struct::Error, /master_username is required/)
    end
  end
end
