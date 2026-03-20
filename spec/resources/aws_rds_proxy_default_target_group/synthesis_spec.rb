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
require 'pangea/resources/aws_rds_proxy_default_target_group/resource'

RSpec.describe 'aws_rds_proxy_default_target_group synthesis' do
  let(:synthesizer) { TerraformSynthesizer.new }

  describe 'terraform synthesis' do
    it 'synthesizes basic default target group' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_rds_proxy_default_target_group(:default, {
          db_proxy_name: 'my-proxy'
        })
      end

      result = synthesizer.synthesis
      tg = result['resource']['aws_db_proxy_default_target_group']['default']

      expect(tg['db_proxy_name']).to eq('my-proxy')
    end

    it 'synthesizes with connection pool config' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_rds_proxy_default_target_group(:with_pool, {
          db_proxy_name: 'my-proxy',
          connection_pool_config: {
            max_connections_percent: 80,
            max_idle_connections_percent: 25
          }
        })
      end

      result = synthesizer.synthesis
      tg = result['resource']['aws_db_proxy_default_target_group']['with_pool']

      expect(tg['connection_pool_config']['max_connections_percent']).to eq(80)
    end
  end

  describe 'resource references' do
    it 'returns a ResourceReference with correct outputs' do
      ref = nil
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        ref = aws_rds_proxy_default_target_group(:test, {
          db_proxy_name: 'test-proxy'
        })
      end

      expect(ref.outputs[:id]).to eq('${aws_db_proxy_default_target_group.test.id}')
      expect(ref.outputs[:arn]).to eq('${aws_db_proxy_default_target_group.test.arn}')
      expect(ref.outputs[:db_proxy_name]).to eq('${aws_db_proxy_default_target_group.test.db_proxy_name}')
    end
  end

  describe 'validation' do
    it 'rejects proxy name starting with number' do
      expect {
        Pangea::Resources::AWS::Types::RdsProxyDefaultTargetGroupAttributes.new({
          db_proxy_name: '123-invalid'
        })
      }.to raise_error(Dry::Struct::Error, /must start with a letter/)
    end

    it 'rejects idle connections exceeding max connections' do
      expect {
        Pangea::Resources::AWS::Types::ProxyDefaultTargetGroupConnectionPoolConfig.new({
          max_connections_percent: 50,
          max_idle_connections_percent: 75
        })
      }.to raise_error(Dry::Struct::Error, /cannot exceed max_connections_percent/)
    end
  end
end
