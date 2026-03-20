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
require 'pangea/resources/aws_rds_proxy/resource'

RSpec.describe 'aws_rds_proxy synthesis' do
  let(:synthesizer) { TerraformSynthesizer.new }

  let(:valid_attrs) do
    {
      db_proxy_name: 'my-proxy',
      engine_family: 'MYSQL',
      role_arn: 'arn:aws:iam::123456789012:role/proxy-role',
      vpc_subnet_ids: ['subnet-111', 'subnet-222'],
      auth: [{
        auth_scheme: 'SECRETS',
        secret_arn: 'arn:aws:secretsmanager:us-east-1:123456789012:secret:db-creds',
        iam_auth: 'DISABLED',
        username: 'admin'
      }]
    }
  end

  describe 'terraform synthesis' do
    it 'synthesizes basic RDS proxy' do
      attrs = valid_attrs
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_rds_proxy(:mysql_proxy, attrs)
      end

      result = synthesizer.synthesis
      proxy = result['resource']['aws_db_proxy']['mysql_proxy']

      expect(proxy['name']).to eq('my-proxy')
      expect(proxy['engine_family']).to eq('MYSQL')
      expect(proxy['require_tls']).to eq(true)
    end

    it 'synthesizes RDS proxy with tags' do
      attrs = valid_attrs.merge(tags: { Environment: 'production' })
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_rds_proxy(:tagged, attrs)
      end

      result = synthesizer.synthesis
      proxy = result['resource']['aws_db_proxy']['tagged']

      expect(proxy['tags']['Environment']).to eq('production')
    end
  end

  describe 'resource references' do
    it 'returns a ResourceReference with correct outputs' do
      ref = nil
      attrs = valid_attrs
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        ref = aws_rds_proxy(:test, attrs)
      end

      expect(ref.outputs[:id]).to eq('${aws_db_proxy.test.id}')
      expect(ref.outputs[:arn]).to eq('${aws_db_proxy.test.arn}')
      expect(ref.outputs[:endpoint]).to eq('${aws_db_proxy.test.endpoint}')
    end
  end

  describe 'validation' do
    it 'rejects proxy name starting with number' do
      expect {
        Pangea::Resources::AWS::Types::RdsProxyAttributes.new(
          valid_attrs.merge(db_proxy_name: '123-invalid')
        )
      }.to raise_error(Dry::Struct::Error, /must start with a letter/)
    end

    it 'rejects fewer than 2 subnets' do
      expect {
        Pangea::Resources::AWS::Types::RdsProxyAttributes.new(
          valid_attrs.merge(vpc_subnet_ids: ['subnet-only-one'])
        )
      }.to raise_error(Dry::Struct::Error, /At least 2 VPC subnets/)
    end
  end
end
