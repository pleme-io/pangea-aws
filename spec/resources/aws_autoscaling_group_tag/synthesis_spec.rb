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
require 'pangea/resources/aws_autoscaling_group_tag/resource'

RSpec.describe 'aws_autoscaling_group_tag synthesis' do
  let(:synthesizer) { TerraformSynthesizer.new }

  describe 'terraform synthesis' do
    it 'synthesizes with tags' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_autoscaling_group_tag(:tagged, {
          tags: { Environment: 'production' }
        })
      end

      result = synthesizer.synthesis
      tag = result[:resource][:aws_autoscaling_group_tag][:tagged]

      expect(tag[:tags][:Environment]).to eq('production')
    end
  end

  describe 'resource references' do
    it 'returns ResourceReference with correct outputs' do
      ref = synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_autoscaling_group_tag(:test, {})
      end

      expect(ref).to be_a(Pangea::Resources::ResourceReference)
      expect(ref.outputs[:id]).to eq('${aws_autoscaling_group_tag.test.id}')
    end
  end
end
