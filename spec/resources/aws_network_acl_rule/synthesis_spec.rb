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
require 'pangea/resources/aws_network_acl_rule/resource'

RSpec.describe "aws_network_acl_rule synthesis" do
  include Pangea::Resources::AWS

  let(:synthesizer) { TerraformSynthesizer.new }

  describe "terraform generation" do
    it "generates valid terraform JSON with required attributes" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_network_acl_rule(:test, {
          network_acl_id: "acl-12345678",
          rule_number: 100,
          protocol: "-1",
          rule_action: "allow",
          cidr_block: "0.0.0.0/0"
        })
      end

      result = synthesizer.synthesis

      expect(result).to have_key("resource")
      expect(result["resource"]).to have_key("aws_network_acl_rule")
      expect(result["resource"]["aws_network_acl_rule"]).to have_key("test")

      config = result["resource"]["aws_network_acl_rule"]["test"]
      expect(config["network_acl_id"]).to eq("acl-12345678")
      expect(config["rule_number"]).to eq(100)
      expect(config["protocol"]).to eq("-1")
      expect(config["rule_action"]).to eq("allow")
      expect(config["cidr_block"]).to eq("0.0.0.0/0")
    end

    it "generates TCP rule with ports" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_network_acl_rule(:tcp_rule, {
          network_acl_id: "acl-12345678",
          rule_number: 200,
          protocol: "tcp",
          rule_action: "allow",
          cidr_block: "10.0.0.0/8",
          from_port: 443,
          to_port: 443
        })
      end

      result = synthesizer.synthesis
      config = result["resource"]["aws_network_acl_rule"]["tcp_rule"]

      expect(config["protocol"]).to eq("tcp")
      expect(config["from_port"]).to eq(443)
      expect(config["to_port"]).to eq(443)
    end

    it "generates egress rule" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_network_acl_rule(:egress_rule, {
          network_acl_id: "acl-12345678",
          rule_number: 100,
          protocol: "-1",
          rule_action: "allow",
          cidr_block: "0.0.0.0/0",
          egress: true
        })
      end

      result = synthesizer.synthesis
      config = result["resource"]["aws_network_acl_rule"]["egress_rule"]

      expect(config["egress"]).to eq(true)
    end

    it "includes tags when provided" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_network_acl_rule(:tagged, {
          network_acl_id: "acl-12345678",
          rule_number: 100,
          protocol: "-1",
          rule_action: "allow",
          cidr_block: "0.0.0.0/0",
          tags: { Name: "test-nacl-rule", Environment: "test" }
        })
      end

      result = synthesizer.synthesis
      config = result["resource"]["aws_network_acl_rule"]["tagged"]

      expect(config).to have_key("tags")
      expect(config["tags"]["Name"]).to eq("test-nacl-rule")
    end
  end

  describe "resource reference" do
    it "returns a ResourceReference with correct outputs" do
      ref = nil
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        ref = aws_network_acl_rule(:test_ref, {
          network_acl_id: "acl-12345678",
          rule_number: 100,
          protocol: "-1",
          rule_action: "allow",
          cidr_block: "0.0.0.0/0"
        })
      end

      expect(ref).to be_a(Pangea::Resources::ResourceReference)
      expect(ref.outputs[:id]).to eq("${aws_network_acl_rule.test_ref.id}")
    end

    it "provides correct computed properties for ingress allow rule" do
      ref = nil
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        ref = aws_network_acl_rule(:test_ref, {
          network_acl_id: "acl-12345678",
          rule_number: 100,
          protocol: "-1",
          rule_action: "allow",
          cidr_block: "0.0.0.0/0"
        })
      end

      expect(ref.computed_properties[:ingress]).to eq(true)
      expect(ref.computed_properties[:allow]).to eq(true)
      expect(ref.computed_properties[:deny]).to eq(false)
      expect(ref.computed_properties[:ipv4]).to eq(true)
      expect(ref.computed_properties[:protocol_name]).to eq("all")
      expect(ref.computed_properties[:rule_type]).to eq("allow ingress")
    end

    it "provides correct computed properties for egress deny rule" do
      ref = nil
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        ref = aws_network_acl_rule(:test_ref, {
          network_acl_id: "acl-12345678",
          rule_number: 100,
          protocol: "tcp",
          rule_action: "deny",
          cidr_block: "10.0.0.0/8",
          from_port: 22,
          to_port: 22,
          egress: true
        })
      end

      expect(ref.computed_properties[:ingress]).to eq(false)
      expect(ref.computed_properties[:deny]).to eq(true)
      expect(ref.computed_properties[:protocol_name]).to eq("tcp")
      expect(ref.computed_properties[:rule_type]).to eq("deny egress")
    end
  end

  describe "terraform validation" do
    it "produces valid terraform structure" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_network_acl_rule(:test, {
          network_acl_id: "acl-12345678",
          rule_number: 100,
          protocol: "-1",
          rule_action: "allow",
          cidr_block: "0.0.0.0/0"
        })
      end

      result = synthesizer.synthesis

      expect(result).to be_a(Hash)
      expect(result["resource"]).to be_a(Hash)
      expect(result["resource"]["aws_network_acl_rule"]).to be_a(Hash)
      expect(result["resource"]["aws_network_acl_rule"]["test"]).to be_a(Hash)
    end

    it "rejects missing cidr_block and ipv6_cidr_block" do
      expect {
        Pangea::Resources::AWS::Types::NetworkAclRuleAttributes.new(
          network_acl_id: "acl-12345678",
          rule_number: 100,
          protocol: "-1",
          rule_action: "allow"
        )
      }.to raise_error(Dry::Struct::Error, /Must specify either/)
    end

    it "rejects specifying both cidr_block and ipv6_cidr_block" do
      expect {
        Pangea::Resources::AWS::Types::NetworkAclRuleAttributes.new(
          network_acl_id: "acl-12345678",
          rule_number: 100,
          protocol: "-1",
          rule_action: "allow",
          cidr_block: "0.0.0.0/0",
          ipv6_cidr_block: "::/0"
        )
      }.to raise_error(Dry::Struct::Error, /Cannot specify both/)
    end

    it "rejects TCP rule without ports" do
      expect {
        Pangea::Resources::AWS::Types::NetworkAclRuleAttributes.new(
          network_acl_id: "acl-12345678",
          rule_number: 100,
          protocol: "tcp",
          rule_action: "allow",
          cidr_block: "0.0.0.0/0"
        )
      }.to raise_error(Dry::Struct::Error, /from_port.*to_port.*required/)
    end

    it "rejects protocol -1 with ports specified" do
      expect {
        Pangea::Resources::AWS::Types::NetworkAclRuleAttributes.new(
          network_acl_id: "acl-12345678",
          rule_number: 100,
          protocol: "-1",
          rule_action: "allow",
          cidr_block: "0.0.0.0/0",
          from_port: 80,
          to_port: 80
        )
      }.to raise_error(Dry::Struct::Error, /Cannot specify ports/)
    end
  end
end
