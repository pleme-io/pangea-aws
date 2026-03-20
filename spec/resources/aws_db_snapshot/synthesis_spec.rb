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
require 'pangea/resources/aws_db_snapshot/resource'

RSpec.describe 'aws_db_snapshot synthesis' do
  let(:synthesizer) { TerraformSynthesizer.new }

  describe 'terraform synthesis' do
    it 'synthesizes basic db snapshot' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_db_snapshot(:backup, {
          db_instance_identifier: 'my-database',
          db_snapshot_identifier: 'my-snapshot'
        })
      end

      result = synthesizer.synthesis
      snapshot = result['resource']['aws_db_snapshot']['backup']

      expect(snapshot['db_instance_identifier']).to eq('my-database')
      expect(snapshot['db_snapshot_identifier']).to eq('my-snapshot')
    end

    it 'synthesizes db snapshot with tags' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_db_snapshot(:tagged, {
          db_instance_identifier: 'my-db',
          db_snapshot_identifier: 'tagged-snap',
          tags: { Purpose: 'backup', Environment: 'production' }
        })
      end

      result = synthesizer.synthesis
      snapshot = result['resource']['aws_db_snapshot']['tagged']

      expect(snapshot['tags']['Purpose']).to eq('backup')
      expect(snapshot['tags']['Environment']).to eq('production')
    end
  end

  describe 'resource references' do
    it 'returns a ResourceReference with correct outputs' do
      ref = nil
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        ref = aws_db_snapshot(:test, {
          db_instance_identifier: 'test-db',
          db_snapshot_identifier: 'test-snapshot'
        })
      end

      expect(ref.outputs[:id]).to eq('${aws_db_snapshot.test.id}')
      expect(ref.outputs[:arn]).to eq('${aws_db_snapshot.test.db_snapshot_arn}')
      expect(ref.outputs[:db_snapshot_identifier]).to eq('${aws_db_snapshot.test.db_snapshot_identifier}')
    end
  end

  describe 'validation' do
    it 'rejects snapshot identifier starting with number' do
      expect {
        Pangea::Resources::AWS::Types::DbSnapshotAttributes.new({
          db_instance_identifier: 'my-db',
          db_snapshot_identifier: '123-invalid'
        })
      }.to raise_error(Dry::Struct::Error, /must start with a letter/)
    end
  end
end
