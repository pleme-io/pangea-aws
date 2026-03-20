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
require 'pangea/resources/aws_network_acl/resource'

RSpec.describe "aws_network_acl synthesis" do
  include Pangea::Resources::AWS

  let(:synthesizer) { TerraformSynthesizer.new }

  describe "terraform generation" do
    it "generates valid terraform JSON with required attributes" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_network_acl(:test, {
          vpc_id: "vpc-12345678"
        })
      end

      result = synthesizer.synthesis

      expect(result).to have_key("resource")
      expect(result["resource"]).to have_key("aws_network_acl")
      expect(result["resource"]["aws_network_acl"]).to have_key("test")

      config = result["resource"]["aws_network_acl"]["test"]
      expect(config["vpc_id"]).to eq("vpc-12345678")
    end

    it "generates terraform JSON with subnet IDs" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_network_acl(:with_subnets, {
          vpc_id: "vpc-12345678",
          subnet_ids: ["subnet-aaa", "subnet-bbb"]
        })
      end

      result = synthesizer.synthesis
      config = result["resource"]["aws_network_acl"]["with_subnets"]

      expect(config["subnet_ids"]).to eq(["subnet-aaa", "subnet-bbb"])
    end

    it "includes tags when provided" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_network_acl(:tagged, {
          vpc_id: "vpc-12345678",
          tags: { Name: "test-nacl", Environment: "test" }
        })
      end

      result = synthesizer.synthesis
      config = result["resource"]["aws_network_acl"]["tagged"]

      expect(config).to have_key("tags")
    end

    it "supports ingress and egress rules" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_network_acl(:with_rules, {
          vpc_id: "vpc-12345678",
          ingress: [
            { rule_number: 100, protocol: "tcp", action: "allow", cidr_block: "0.0.0.0/0", from_port: 80, to_port: 80 }
          ],
          egress: [
            { rule_number: 100, protocol: "-1", action: "allow", cidr_block: "0.0.0.0/0" }
          ]
        })
      end

      result = synthesizer.synthesis
      config = result["resource"]["aws_network_acl"]["with_rules"]

      expect(config).to have_key("ingress")
      expect(config).to have_key("egress")
    end
  end

  describe "resource reference" do
    it "returns a ResourceReference with correct outputs" do
      ref = nil
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        ref = aws_network_acl(:test_ref, {
          vpc_id: "vpc-12345678"
        })
      end

      expect(ref).to be_a(Pangea::Resources::ResourceReference)
      expect(ref.outputs[:id]).to eq("${aws_network_acl.test_ref.id}")
      expect(ref.outputs[:arn]).to eq("${aws_network_acl.test_ref.arn}")
      expect(ref.outputs[:vpc_id]).to eq("${aws_network_acl.test_ref.vpc_id}")
      expect(ref.outputs[:owner_id]).to eq("${aws_network_acl.test_ref.owner_id}")
    end
  end

  describe "terraform validation" do
    it "produces valid terraform structure" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_network_acl(:test, {
          vpc_id: "vpc-12345678"
        })
      end

      result = synthesizer.synthesis

      expect(result).to be_a(Hash)
      expect(result["resource"]).to be_a(Hash)
      expect(result["resource"]["aws_network_acl"]).to be_a(Hash)
      expect(result["resource"]["aws_network_acl"]["test"]).to be_a(Hash)
    end

    it "rejects duplicate ingress rule numbers" do
      expect {
        Pangea::Resources::AWS::Types::NetworkAclAttributes.new(
          vpc_id: "vpc-12345678",
          ingress: [
            { rule_number: 100, protocol: "-1", action: "allow", cidr_block: "0.0.0.0/0" },
            { rule_number: 100, protocol: "-1", action: "deny", cidr_block: "10.0.0.0/8" }
          ]
        )
      }.to raise_error(Dry::Struct::Error, /Duplicate ingress rule numbers/)
    end

    it "rejects duplicate egress rule numbers" do
      expect {
        Pangea::Resources::AWS::Types::NetworkAclAttributes.new(
          vpc_id: "vpc-12345678",
          egress: [
            { rule_number: 100, protocol: "-1", action: "allow", cidr_block: "0.0.0.0/0" },
            { rule_number: 100, protocol: "-1", action: "deny", cidr_block: "10.0.0.0/8" }
          ]
        )
      }.to raise_error(Dry::Struct::Error, /Duplicate egress rule numbers/)
    end
  end
end
