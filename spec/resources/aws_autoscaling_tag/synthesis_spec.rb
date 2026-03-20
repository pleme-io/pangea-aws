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
require 'pangea/resources/aws_autoscaling_tag/resource'

RSpec.describe 'aws_autoscaling_tag synthesis' do
  describe 'type validation' do
    it 'accepts valid tag attributes' do
      attrs = Pangea::Resources::AWS::Types::AutoScalingTagAttributes.new(
        autoscaling_group_name: '${aws_autoscaling_group.web.name}',
        tags: [
          { key: 'Environment', value: 'production', propagate_at_launch: true }
        ]
      )

      expect(attrs.autoscaling_group_name).to eq('${aws_autoscaling_group.web.name}')
      expect(attrs.tags.length).to eq(1)
      expect(attrs.tags.first.key).to eq('Environment')
    end

    it 'accepts multiple tags with propagate_at_launch true' do
      attrs = Pangea::Resources::AWS::Types::AutoScalingTagAttributes.new(
        autoscaling_group_name: '${aws_autoscaling_group.web.name}',
        tags: [
          { key: 'Environment', value: 'production', propagate_at_launch: true },
          { key: 'Team', value: 'platform', propagate_at_launch: true }
        ]
      )

      expect(attrs.tags.length).to eq(2)
    end

    it 'serializes to hash' do
      attrs = Pangea::Resources::AWS::Types::AutoScalingTagAttributes.new(
        autoscaling_group_name: 'my-asg',
        tags: [
          { key: 'Environment', value: 'production', propagate_at_launch: true }
        ]
      )

      expect(attrs.to_h[:tags].length).to eq(1)
      expect(attrs.to_h[:autoscaling_group_name]).to eq('my-asg')
    end
  end
end
