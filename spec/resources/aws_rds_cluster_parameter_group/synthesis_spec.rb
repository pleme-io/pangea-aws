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
require 'pangea/resources/aws_rds_cluster_parameter_group/resource'

RSpec.describe 'aws_rds_cluster_parameter_group synthesis' do
  let(:synthesizer) { TerraformSynthesizer.new }

  describe 'terraform synthesis' do
    it 'synthesizes basic parameter group' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_rds_cluster_parameter_group(:mysql_params, {
          name: 'aurora-mysql-params',
          family: 'aurora-mysql8.0',
          description: 'Custom Aurora MySQL parameter group'
        })
      end

      result = synthesizer.synthesis
      pg = result['resource']['aws_rds_cluster_parameter_group']['mysql_params']

      expect(pg['name']).to eq('aurora-mysql-params')
      expect(pg['family']).to eq('aurora-mysql8.0')
      expect(pg['description']).to eq('Custom Aurora MySQL parameter group')
    end

    it 'synthesizes parameter group with tags' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_rds_cluster_parameter_group(:tagged, {
          name: 'tagged-params',
          family: 'aurora-postgresql15',
          tags: { Environment: 'production' }
        })
      end

      result = synthesizer.synthesis
      pg = result['resource']['aws_rds_cluster_parameter_group']['tagged']

      expect(pg['tags']['Environment']).to eq('production')
    end
  end

  describe 'resource references' do
    it 'returns a ResourceReference with correct outputs' do
      ref = nil
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        ref = aws_rds_cluster_parameter_group(:test, {
          name: 'test-params',
          family: 'aurora-mysql8.0'
        })
      end

      expect(ref.outputs[:id]).to eq('${aws_rds_cluster_parameter_group.test.id}')
      expect(ref.outputs[:arn]).to eq('${aws_rds_cluster_parameter_group.test.arn}')
      expect(ref.outputs[:family]).to eq('${aws_rds_cluster_parameter_group.test.family}')
    end
  end

  describe 'validation' do
    it 'rejects both name and name_prefix' do
      expect {
        Pangea::Resources::AWS::Types::RdsClusterParameterGroupAttributes.new({
          name: 'my-params',
          name_prefix: 'my-prefix',
          family: 'aurora-mysql8.0'
        })
      }.to raise_error(Dry::Struct::Error, /Cannot specify both/)
    end
  end
end
