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
require 'pangea/resources/aws_lb_listener_certificate/resource'

RSpec.describe 'aws_lb_listener_certificate synthesis' do
  let(:synthesizer) { TerraformSynthesizer.new }

  let(:valid_listener_arn) { 'arn:aws:elasticloadbalancing:us-east-1:123456789012:listener/app/my-alb/1234567890/abcdef' }
  let(:valid_certificate_arn) { 'arn:aws:acm:us-east-1:123456789012:certificate/abcdef01-2345-6789-abcd-ef0123456789' }

  describe 'terraform synthesis' do
    it 'synthesizes with valid attributes' do
      listener_arn = valid_listener_arn
      certificate_arn = valid_certificate_arn
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_lb_listener_certificate(:test, {
          listener_arn: listener_arn,
          certificate_arn: certificate_arn
        })
      end

      result = synthesizer.synthesis
      cert = result[:resource][:aws_lb_listener_certificate][:test]

      expect(cert[:listener_arn]).to eq(valid_listener_arn)
      expect(cert[:certificate_arn]).to eq(valid_certificate_arn)
    end
  end

  describe 'resource references' do
    it 'returns ResourceReference with correct outputs' do
      listener_arn = valid_listener_arn
      certificate_arn = valid_certificate_arn
      ref = synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_lb_listener_certificate(:test, {
          listener_arn: listener_arn,
          certificate_arn: certificate_arn
        })
      end

      expect(ref).to be_a(Pangea::Resources::ResourceReference)
      expect(ref.outputs[:listener_arn]).to eq('${aws_lb_listener_certificate.test.listener_arn}')
      expect(ref.outputs[:certificate_arn]).to eq('${aws_lb_listener_certificate.test.certificate_arn}')
    end
  end

  describe 'validation' do
    it 'rejects mismatched regions between listener and certificate' do
      expect {
        Pangea::Resources::AWS::Types::LoadBalancerListenerCertificateAttributes.new(
          listener_arn: 'arn:aws:elasticloadbalancing:us-east-1:123456789012:listener/app/my-alb/1234567890/abcdef',
          certificate_arn: 'arn:aws:acm:us-west-2:123456789012:certificate/abcdef01-2345-6789-abcd-ef0123456789'
        )
      }.to raise_error(Dry::Struct::Error, /region/)
    end
  end
end
