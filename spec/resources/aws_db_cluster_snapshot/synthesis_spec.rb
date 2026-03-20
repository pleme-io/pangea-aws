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
require 'pangea/resources/aws_db_cluster_snapshot/resource'

RSpec.describe 'aws_db_cluster_snapshot synthesis' do
  let(:synthesizer) { TerraformSynthesizer.new }

  describe 'terraform synthesis' do
    it 'synthesizes basic cluster snapshot' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_db_cluster_snapshot(:backup, {
          db_cluster_identifier: 'my-aurora-cluster',
          db_cluster_snapshot_identifier: 'my-cluster-snapshot'
        })
      end

      result = synthesizer.synthesis
      snapshot = result['resource']['aws_rds_cluster_snapshot']['backup']

      expect(snapshot['db_cluster_identifier']).to eq('my-aurora-cluster')
      expect(snapshot['db_cluster_snapshot_identifier']).to eq('my-cluster-snapshot')
    end

    it 'synthesizes cluster snapshot with tags' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_db_cluster_snapshot(:tagged, {
          db_cluster_identifier: 'my-cluster',
          db_cluster_snapshot_identifier: 'tagged-snapshot',
          tags: { Purpose: 'backup', Environment: 'production' }
        })
      end

      result = synthesizer.synthesis
      snapshot = result['resource']['aws_rds_cluster_snapshot']['tagged']

      expect(snapshot['tags']['Purpose']).to eq('backup')
      expect(snapshot['tags']['Environment']).to eq('production')
    end
  end

  describe 'resource references' do
    it 'returns a ResourceReference with correct outputs' do
      ref = nil
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        ref = aws_db_cluster_snapshot(:test, {
          db_cluster_identifier: 'test-cluster',
          db_cluster_snapshot_identifier: 'test-snapshot'
        })
      end

      expect(ref.outputs[:id]).to eq('${aws_rds_cluster_snapshot.test.id}')
      expect(ref.outputs[:arn]).to eq('${aws_rds_cluster_snapshot.test.db_cluster_snapshot_arn}')
      expect(ref.outputs[:db_cluster_snapshot_identifier]).to eq('${aws_rds_cluster_snapshot.test.db_cluster_snapshot_identifier}')
    end
  end

  describe 'validation' do
    it 'rejects snapshot identifier starting with number' do
      expect {
        Pangea::Resources::AWS::Types::DbClusterSnapshotAttributes.new({
          db_cluster_identifier: 'my-cluster',
          db_cluster_snapshot_identifier: '123-invalid'
        })
      }.to raise_error(Dry::Struct::Error, /must start with a letter/)
    end
  end
end
