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
require 'pangea/resources/aws_iam_instance_profile/resource'

RSpec.describe 'aws_iam_instance_profile synthesis' do
  let(:synthesizer) { TerraformSynthesizer.new }

  describe 'terraform synthesis' do
    it 'synthesizes instance profile with name, role, and tags' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_iam_instance_profile(:web_profile, {
          name: 'web-instance-profile',
          role: 'web-server-role',
          tags: { Environment: 'production', Team: 'platform' }
        })
      end

      result = synthesizer.synthesis
      profile = result[:resource][:aws_iam_instance_profile][:web_profile]

      expect(profile[:name]).to eq('web-instance-profile')
      expect(profile[:role]).to eq('web-server-role')
      expect(profile[:tags][:Environment]).to eq('production')
      expect(profile[:tags][:Team]).to eq('platform')
    end

    it 'synthesizes instance profile with custom path' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_iam_instance_profile(:pathed, {
          name: 'pathed-profile',
          role: 'some-role',
          path: '/application/'
        })
      end

      result = synthesizer.synthesis
      profile = result[:resource][:aws_iam_instance_profile][:pathed]

      expect(profile[:path]).to eq('/application/')
    end

    it 'synthesizes instance profile with terraform reference in role' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_iam_instance_profile(:ref_profile, {
          name: 'ref-profile',
          role: '${aws_iam_role.web.name}'
        })
      end

      result = synthesizer.synthesis
      profile = result[:resource][:aws_iam_instance_profile][:ref_profile]

      expect(profile[:role]).to eq('${aws_iam_role.web.name}')
    end
  end

  describe 'resource references' do
    it 'returns ResourceReference with correct outputs' do
      ref = synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_iam_instance_profile(:test, {
          name: 'test-profile',
          role: 'test-role'
        })
      end

      expect(ref.outputs[:id]).to eq('${aws_iam_instance_profile.test.id}')
      expect(ref.outputs[:arn]).to eq('${aws_iam_instance_profile.test.arn}')
      expect(ref.outputs[:name]).to eq('${aws_iam_instance_profile.test.name}')
      expect(ref.outputs[:unique_id]).to eq('${aws_iam_instance_profile.test.unique_id}')
      expect(ref.outputs[:create_date]).to eq('${aws_iam_instance_profile.test.create_date}')
    end
  end

  describe 'name/name_prefix mutual exclusivity' do
    it 'raises error when both name and name_prefix are specified' do
      expect do
        synthesizer.instance_eval do
          extend Pangea::Resources::AWS
          aws_iam_instance_profile(:invalid, {
            name: 'my-profile',
            name_prefix: 'my-prefix',
            role: 'some-role'
          })
        end
      end.to raise_error(Dry::Struct::Error, /Cannot specify both/)
    end

    it 'synthesizes with name_prefix instead of name' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_iam_instance_profile(:prefixed, {
          name_prefix: 'app-',
          role: 'app-role'
        })
      end

      result = synthesizer.synthesis
      profile = result[:resource][:aws_iam_instance_profile][:prefixed]

      expect(profile[:name_prefix]).to eq('app-')
      expect(profile[:role]).to eq('app-role')
    end
  end
end
