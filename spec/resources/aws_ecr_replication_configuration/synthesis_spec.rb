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
require 'pangea/resources/aws_ecr_replication_configuration/resource'

RSpec.describe "aws_ecr_replication_configuration synthesis" do
  include Pangea::Resources::AWS

  let(:synthesizer) { TerraformSynthesizer.new }

  describe "terraform generation" do
    it "generates valid terraform JSON for cross-region replication" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_ecr_replication_configuration(:test, {
          replication_configuration: {
            rule: [
              {
                destination: [
                  { region: "us-west-2" },
                  { region: "eu-west-1" }
                ]
              }
            ]
          }
        })
      end

      result = synthesizer.synthesis

      expect(result).to have_key("resource")
      expect(result["resource"]).to have_key("aws_ecr_replication_configuration")
      expect(result["resource"]["aws_ecr_replication_configuration"]).to have_key("test")

      config = result["resource"]["aws_ecr_replication_configuration"]["test"]
      expect(config).to have_key("replication_configuration")
    end

    it "supports cross-account replication" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_ecr_replication_configuration(:test, {
          replication_configuration: {
            rule: [
              {
                destination: [
                  { region: "us-east-1", registry_id: "123456789012" }
                ]
              }
            ]
          }
        })
      end

      result = synthesizer.synthesis
      config = result["resource"]["aws_ecr_replication_configuration"]["test"]

      expect(config).to have_key("replication_configuration")
    end
  end

  describe "terraform validation" do
    it "produces valid terraform structure" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_ecr_replication_configuration(:test, {
          replication_configuration: {
            rule: [
              {
                destination: [
                  { region: "us-west-2" }
                ]
              }
            ]
          }
        })
      end

      result = synthesizer.synthesis

      expect(result).to be_a(Hash)
      expect(result["resource"]).to be_a(Hash)
      expect(result["resource"]["aws_ecr_replication_configuration"]).to be_a(Hash)
      expect(result["resource"]["aws_ecr_replication_configuration"]["test"]).to be_a(Hash)
    end

    it "rejects empty rules array" do
      expect {
        synthesizer.instance_eval do
          extend Pangea::Resources::AWS
          aws_ecr_replication_configuration(:test, {
            replication_configuration: {
              rule: []
            }
          })
        end
      }.to raise_error(Dry::Struct::Error, /at least one rule/)
    end

    it "rejects invalid region format" do
      expect {
        synthesizer.instance_eval do
          extend Pangea::Resources::AWS
          aws_ecr_replication_configuration(:test, {
            replication_configuration: {
              rule: [
                {
                  destination: [
                    { region: "invalid-region" }
                  ]
                }
              ]
            }
          })
        end
      }.to raise_error(Dry::Struct::Error, /valid AWS region/)
    end
  end

  describe "resource references" do
    it "returns a resource reference with outputs" do
      ref = nil
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        ref = aws_ecr_replication_configuration(:test, {
          replication_configuration: {
            rule: [
              {
                destination: [
                  { region: "us-west-2" }
                ]
              }
            ]
          }
        })
      end

      expect(ref).to be_a(Pangea::Resources::ResourceReference)
      expect(ref.outputs[:registry_id]).to eq("${aws_ecr_replication_configuration.test.registry_id}")
    end

    it "provides computed properties for cross-region replication" do
      ref = nil
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        ref = aws_ecr_replication_configuration(:test, {
          replication_configuration: {
            rule: [
              {
                destination: [
                  { region: "us-west-2" },
                  { region: "eu-west-1" }
                ]
              }
            ]
          }
        })
      end

      expect(ref.rule_count).to eq(1)
      expect(ref.destination_count).to eq(2)
      expect(ref.destination_regions).to contain_exactly("eu-west-1", "us-west-2")
      expect(ref.has_cross_region_replication).to eq(true)
      expect(ref.is_same_account_replication).to eq(true)
      expect(ref.replication_scope).to eq(:cross_region)
    end

    it "provides computed properties for cross-account replication" do
      ref = nil
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        ref = aws_ecr_replication_configuration(:test, {
          replication_configuration: {
            rule: [
              {
                destination: [
                  { region: "us-east-1", registry_id: "123456789012" },
                  { region: "us-west-2", registry_id: "987654321098" }
                ]
              }
            ]
          }
        })
      end

      expect(ref.has_cross_account_replication).to eq(true)
      expect(ref.destination_accounts).to contain_exactly("123456789012", "987654321098")
      expect(ref.replication_scope).to eq(:cross_account_cross_region)
    end
  end
end
