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
require 'pangea/resources/aws_rds_proxy_target/resource'

RSpec.describe 'aws_rds_proxy_target synthesis' do
  let(:synthesizer) { TerraformSynthesizer.new }

  describe 'terraform synthesis' do
    it 'synthesizes instance target' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_rds_proxy_target(:instance_target, {
          db_proxy_name: 'my-proxy',
          target_group_name: 'default',
          db_instance_identifier: 'my-db-instance'
        })
      end

      result = synthesizer.synthesis
      target = result['resource']['aws_db_proxy_target']['instance_target']

      expect(target['db_proxy_name']).to eq('my-proxy')
      expect(target['target_group_name']).to eq('default')
      expect(target['db_instance_identifier']).to eq('my-db-instance')
    end

    it 'synthesizes cluster target' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_rds_proxy_target(:cluster_target, {
          db_proxy_name: 'my-proxy',
          target_group_name: 'default',
          db_cluster_identifier: 'my-aurora-cluster'
        })
      end

      result = synthesizer.synthesis
      target = result['resource']['aws_db_proxy_target']['cluster_target']

      expect(target['db_cluster_identifier']).to eq('my-aurora-cluster')
    end
  end

  describe 'resource references' do
    it 'returns a ResourceReference with correct outputs' do
      ref = nil
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        ref = aws_rds_proxy_target(:test, {
          db_proxy_name: 'test-proxy',
          target_group_name: 'default',
          db_cluster_identifier: 'test-cluster'
        })
      end

      expect(ref.outputs[:id]).to eq('${aws_db_proxy_target.test.id}')
      expect(ref.outputs[:endpoint]).to eq('${aws_db_proxy_target.test.endpoint}')
      expect(ref.outputs[:target_arn]).to eq('${aws_db_proxy_target.test.target_arn}')
    end
  end

  describe 'validation' do
    it 'rejects specifying both instance and cluster identifier' do
      expect {
        Pangea::Resources::AWS::Types::RdsProxyTargetAttributes.new({
          db_proxy_name: 'my-proxy',
          target_group_name: 'default',
          db_instance_identifier: 'my-instance',
          db_cluster_identifier: 'my-cluster'
        })
      }.to raise_error(Dry::Struct::Error, /Must specify exactly one/)
    end

    it 'rejects specifying neither instance nor cluster identifier' do
      expect {
        Pangea::Resources::AWS::Types::RdsProxyTargetAttributes.new({
          db_proxy_name: 'my-proxy',
          target_group_name: 'default'
        })
      }.to raise_error(Dry::Struct::Error, /Must specify exactly one/)
    end
  end
end
