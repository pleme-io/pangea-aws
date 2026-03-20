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
require 'pangea/resources/aws_key_pair/resource'

RSpec.describe 'aws_key_pair synthesis' do
  let(:synthesizer) { TerraformSynthesizer.new }
  let(:rsa_public_key) do
    'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC7vbqajDRETmoIFMFoaPISvGXCkwyLcMEyVaCfuOb7K3aBbWMGiXMgPsTLviXfN6fueGPMz5b6AafEJoGnELo6RlXai0ztLMNhaTzROVEBpEiDRq4aNiKRCn4xyoFSRHDPhS6JFafqxLJiE3DGHaBR9GEbO0tXHfDNVKKchFMi3FnGrFd2jXBskPBVB5fw3Y31qaFECpPiDPEhRsMrQf0Dvj1AqKGHzFi4FkMlY0RZkJn6rOHrKbqNEBE3yBaNMlW3n2cvBmE0JgeFBGE3sPN6tx9yzAKBRXwomRnHoS0ZMBiELsDk3NMfSmFMB0w3Gv9faXWiBkIrYDIkYWuA0cMHy1V4gRJgKwQjCfE5FFbRW0SXWKaPsBHsjiBd2AU1VFO7KJYhu5GWgr62PYmcbJFwHN9XWCALvPkJgp3HIhRbHONVSrJG3NU8s9LOQbMNk3N1BTrLA3ci7sYPXBnqMbvfML79rreMGQ9p0DZHQBITNIYG3hse+xhN0u3G2PiY0= test@example.com'
  end
  let(:ed25519_public_key) do
    'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl test@example.com'
  end

  describe 'terraform synthesis' do
    it 'synthesizes key pair with key_name and public_key' do
      pub_key = rsa_public_key
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_key_pair(:deploy, {
          key_name: 'deploy-key',
          public_key: pub_key
        })
      end

      result = synthesizer.synthesis
      kp = result[:resource][:aws_key_pair][:deploy]

      expect(kp[:key_name]).to eq('deploy-key')
      expect(kp[:public_key]).to eq(pub_key)
    end

    it 'synthesizes key pair with tags' do
      pub_key = ed25519_public_key
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_key_pair(:tagged, {
          key_name: 'tagged-key',
          public_key: pub_key,
          tags: { Environment: 'staging', ManagedBy: 'pangea' }
        })
      end

      result = synthesizer.synthesis
      kp = result[:resource][:aws_key_pair][:tagged]

      expect(kp[:tags][:Environment]).to eq('staging')
      expect(kp[:tags][:ManagedBy]).to eq('pangea')
    end

    it 'synthesizes key pair with key_name_prefix' do
      pub_key = rsa_public_key
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_key_pair(:prefixed, {
          key_name_prefix: 'app-',
          public_key: pub_key
        })
      end

      result = synthesizer.synthesis
      kp = result[:resource][:aws_key_pair][:prefixed]

      expect(kp[:key_name_prefix]).to eq('app-')
    end
  end

  describe 'resource references' do
    it 'returns ResourceReference with correct outputs' do
      pub_key = rsa_public_key
      ref = synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_key_pair(:test, {
          key_name: 'test-key',
          public_key: pub_key
        })
      end

      expect(ref.outputs[:arn]).to eq('${aws_key_pair.test.arn}')
      expect(ref.outputs[:fingerprint]).to eq('${aws_key_pair.test.fingerprint}')
      expect(ref.outputs[:id]).to eq('${aws_key_pair.test.id}')
      expect(ref.outputs[:key_name]).to eq('${aws_key_pair.test.key_name}')
      expect(ref.outputs[:key_pair_id]).to eq('${aws_key_pair.test.key_pair_id}')
      expect(ref.outputs[:key_type]).to eq('${aws_key_pair.test.key_type}')
      expect(ref.outputs[:public_key]).to eq('${aws_key_pair.test.public_key}')
      expect(ref.outputs[:tags_all]).to eq('${aws_key_pair.test.tags_all}')
    end
  end

  describe 'validation' do
    it 'raises error when both key_name and key_name_prefix are specified' do
      pub_key = rsa_public_key
      expect do
        synthesizer.instance_eval do
          extend Pangea::Resources::AWS
          aws_key_pair(:invalid, {
            key_name: 'my-key',
            key_name_prefix: 'my-prefix',
            public_key: pub_key
          })
        end
      end.to raise_error(Dry::Struct::Error, /Cannot specify both/)
    end

    it 'raises error when neither key_name nor key_name_prefix is specified' do
      pub_key = rsa_public_key
      expect do
        synthesizer.instance_eval do
          extend Pangea::Resources::AWS
          aws_key_pair(:missing_name, {
            public_key: pub_key
          })
        end
      end.to raise_error(Dry::Struct::Error, /Must specify either/)
    end
  end
end
