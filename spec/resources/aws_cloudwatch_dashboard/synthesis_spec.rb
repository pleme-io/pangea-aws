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
require 'pangea/resources/aws_cloudwatch_dashboard/resource'

RSpec.describe 'aws_cloudwatch_dashboard synthesis' do
  let(:synthesizer) { TerraformSynthesizer.new }

  describe 'terraform synthesis' do
    it 'synthesizes dashboard with JSON body' do
      body_json = JSON.generate({ widgets: [] })
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_cloudwatch_dashboard(:app_dashboard, {
          dashboard_name: 'application-monitoring',
          dashboard_body_json: body_json
        })
      end

      result = synthesizer.synthesis
      dashboard = result['resource']['aws_cloudwatch_dashboard']['app_dashboard']

      expect(dashboard['dashboard_name']).to eq('application-monitoring')
    end

    it 'synthesizes dashboard with hash body' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_cloudwatch_dashboard(:hash_body, {
          dashboard_name: 'hash-dashboard',
          dashboard_body: { widgets: [] }
        })
      end

      result = synthesizer.synthesis
      dashboard = result['resource']['aws_cloudwatch_dashboard']['hash_body']

      expect(dashboard['dashboard_name']).to eq('hash-dashboard')
    end
  end

  describe 'resource references' do
    it 'returns a ResourceReference with correct outputs' do
      ref = nil
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        ref = aws_cloudwatch_dashboard(:test, {
          dashboard_name: 'test-dashboard',
          dashboard_body_json: JSON.generate({ widgets: [] })
        })
      end

      expect(ref.outputs[:dashboard_arn]).to eq('${aws_cloudwatch_dashboard.test.dashboard_arn}')
      expect(ref.outputs[:dashboard_name]).to eq('${aws_cloudwatch_dashboard.test.dashboard_name}')
    end
  end

  describe 'validation' do
    it 'rejects empty dashboard name' do
      expect {
        Pangea::Resources::AWS::Types::CloudWatchDashboardAttributes.new({
          dashboard_name: '',
          dashboard_body_json: JSON.generate({ widgets: [] })
        })
      }.to raise_error(Dry::Struct::Error, /cannot be empty/)
    end

    it 'rejects when no body is provided' do
      expect {
        Pangea::Resources::AWS::Types::CloudWatchDashboardAttributes.new({
          dashboard_name: 'test'
        })
      }.to raise_error(Dry::Struct::Error, /Must provide one of/)
    end
  end
end
