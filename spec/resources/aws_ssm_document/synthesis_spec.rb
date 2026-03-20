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
require 'pangea/resources/aws_ssm_document/resource'

RSpec.describe 'aws_ssm_document synthesis' do
  let(:synthesizer) { TerraformSynthesizer.new }

  let(:simple_content) do
    JSON.generate({
      'schemaVersion' => '2.2',
      'description' => 'Run a shell command',
      'mainSteps' => [{
        'action' => 'aws:runShellScript',
        'name' => 'runCommand',
        'inputs' => { 'runCommand' => ['echo hello'] }
      }]
    })
  end

  describe 'terraform synthesis' do
    it 'synthesizes basic SSM document' do
      content = simple_content
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_ssm_document(:run_cmd, {
          name: 'MyRunCommand',
          document_type: 'Command',
          content: content
        })
      end

      result = synthesizer.synthesis
      doc = result['resource']['aws_ssm_document']['run_cmd']

      expect(doc['document_name']).to eq('MyRunCommand')
      expect(doc['document_type']).to eq('Command')
      expect(doc['document_format']).to eq('JSON')
    end

    it 'synthesizes SSM document with tags' do
      content = simple_content
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_ssm_document(:tagged, {
          name: 'TaggedDocument',
          document_type: 'Command',
          content: content,
          tags: { Environment: 'production', ManagedBy: 'terraform' }
        })
      end

      result = synthesizer.synthesis
      doc = result['resource']['aws_ssm_document']['tagged']

      expect(doc['tags']['Environment']).to eq('production')
      expect(doc['tags']['ManagedBy']).to eq('terraform')
    end

    it 'synthesizes SSM automation document' do
      automation_content = JSON.generate({
        'schemaVersion' => '0.3',
        'description' => 'Automation document',
        'mainSteps' => [{
          'action' => 'aws:executeScript',
          'name' => 'runScript',
          'inputs' => { 'Runtime' => 'python3.8', 'Script' => 'print("hello")' }
        }]
      })
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_ssm_document(:automation, {
          name: 'MyAutomation',
          document_type: 'Automation',
          content: automation_content
        })
      end

      result = synthesizer.synthesis
      doc = result['resource']['aws_ssm_document']['automation']

      expect(doc['document_type']).to eq('Automation')
    end
  end

  describe 'resource references' do
    it 'returns a ResourceReference with correct outputs' do
      ref = nil
      content = simple_content
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        ref = aws_ssm_document(:test, {
          name: 'TestDocument',
          document_type: 'Command',
          content: content
        })
      end

      expect(ref.outputs[:name]).to eq('${aws_ssm_document.test.name}')
      expect(ref.outputs[:arn]).to eq('${aws_ssm_document.test.arn}')
      expect(ref.outputs[:document_type]).to eq('${aws_ssm_document.test.document_type}')
    end
  end

  describe 'validation' do
    it 'rejects invalid JSON content' do
      expect {
        Pangea::Resources::AWS::Types::SsmDocumentAttributes.new({
          name: 'TestDoc',
          document_type: 'Command',
          content: 'not-valid-json'
        })
      }.to raise_error(Dry::Struct::Error, /Invalid JSON content/)
    end

    it 'rejects document name shorter than 3 characters' do
      expect {
        Pangea::Resources::AWS::Types::SsmDocumentAttributes.new({
          name: 'Ab',
          document_type: 'Command',
          content: simple_content
        })
      }.to raise_error(Dry::Struct::Error, /must be 3-128 characters/)
    end
  end
end
