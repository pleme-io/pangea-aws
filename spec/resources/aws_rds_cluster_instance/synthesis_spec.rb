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
require 'pangea/resources/aws_rds_cluster_instance/resource'

RSpec.describe 'aws_rds_cluster_instance synthesis' do
  let(:synthesizer) { TerraformSynthesizer.new }

  describe 'terraform synthesis' do
    it 'synthesizes basic cluster instance' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_rds_cluster_instance(:writer, {
          cluster_identifier: 'my-aurora-cluster',
          instance_class: 'db.r6g.large',
          engine: 'aurora-mysql'
        })
      end

      result = synthesizer.synthesis
      instance = result['resource']['aws_rds_cluster_instance']['writer']

      expect(instance['cluster_identifier']).to eq('my-aurora-cluster')
      expect(instance['instance_class']).to eq('db.r6g.large')
      expect(instance['engine']).to eq('aurora-mysql')
    end

    it 'synthesizes cluster instance with tags' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_rds_cluster_instance(:tagged, {
          cluster_identifier: 'my-cluster',
          instance_class: 'db.r6g.large',
          tags: { Name: 'writer-instance', Environment: 'production' }
        })
      end

      result = synthesizer.synthesis
      instance = result['resource']['aws_rds_cluster_instance']['tagged']

      expect(instance['tags']['Name']).to eq('writer-instance')
      expect(instance['tags']['Environment']).to eq('production')
    end

    it 'synthesizes cluster instance with performance insights' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_rds_cluster_instance(:insights, {
          cluster_identifier: 'my-cluster',
          instance_class: 'db.r6g.large',
          performance_insights_enabled: true,
          performance_insights_retention_period: 31
        })
      end

      result = synthesizer.synthesis
      instance = result['resource']['aws_rds_cluster_instance']['insights']

      expect(instance['performance_insights_enabled']).to eq(true)
      expect(instance['performance_insights_retention_period']).to eq(31)
    end
  end

  describe 'resource references' do
    it 'returns a ResourceReference with correct outputs' do
      ref = nil
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        ref = aws_rds_cluster_instance(:test, {
          cluster_identifier: 'test-cluster',
          instance_class: 'db.r6g.large'
        })
      end

      expect(ref.outputs[:id]).to eq('${aws_rds_cluster_instance.test.id}')
      expect(ref.outputs[:arn]).to eq('${aws_rds_cluster_instance.test.arn}')
      expect(ref.outputs[:endpoint]).to eq('${aws_rds_cluster_instance.test.endpoint}')
    end
  end

  describe 'validation' do
    it 'rejects both identifier and identifier_prefix' do
      expect {
        Pangea::Resources::AWS::Types::RdsClusterInstanceAttributes.new({
          identifier: 'my-instance',
          identifier_prefix: 'my-prefix',
          cluster_identifier: 'my-cluster',
          instance_class: 'db.r6g.large'
        })
      }.to raise_error(Dry::Struct::Error, /Cannot specify both/)
    end
  end
end
