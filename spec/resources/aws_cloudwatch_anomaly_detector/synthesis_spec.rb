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
require 'pangea/resources/aws_cloudwatch_anomaly_detector/resource'

RSpec.describe 'aws_cloudwatch_anomaly_detector synthesis' do
  let(:synthesizer) { TerraformSynthesizer.new }

  describe 'terraform synthesis' do
    it 'synthesizes basic anomaly detector' do
      pending 'Base.transform_attributes not yet implemented in pangea-core'
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_cloudwatch_anomaly_detector(:cpu_anomaly, {
          metric_name: 'CPUUtilization',
          namespace: 'AWS/EC2',
          stat: 'Average'
        })
      end

      result = synthesizer.synthesis
      detector = result[:resource][:aws_cloudwatch_anomaly_detector][:cpu_anomaly]

      expect(detector[:metric_name]).to eq('CPUUtilization')
      expect(detector[:namespace]).to eq('AWS/EC2')
      expect(detector[:stat]).to eq('Average')
    end

    it 'synthesizes anomaly detector with tags' do
      pending 'Base.transform_attributes not yet implemented in pangea-core'
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_cloudwatch_anomaly_detector(:tagged, {
          metric_name: 'DatabaseConnections',
          namespace: 'AWS/RDS',
          stat: 'Average',
          tags: { Environment: 'production', Team: 'platform' }
        })
      end

      result = synthesizer.synthesis
      detector = result[:resource][:aws_cloudwatch_anomaly_detector][:tagged]

      expect(detector[:tags][:Environment]).to eq('production')
    end
  end

  describe 'resource references' do
    it 'provides correct terraform interpolation strings' do
      pending 'Base.transform_attributes not yet implemented in pangea-core'
      ref = synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_cloudwatch_anomaly_detector(:test, {
          metric_name: 'CPUUtilization',
          namespace: 'AWS/EC2',
          stat: 'Average'
        })
      end

      expect(ref.outputs[:arn]).to eq('${aws_cloudwatch_anomaly_detector.test.arn}')
      expect(ref.outputs[:id]).to eq('${aws_cloudwatch_anomaly_detector.test.id}')
    end
  end
end
