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
require 'pangea/resources/aws_network_interface/resource'

RSpec.describe "aws_network_interface synthesis" do
  include Pangea::Resources::AWS

  let(:synthesizer) { TerraformSynthesizer.new }

  describe "terraform generation" do
    it "generates valid terraform JSON with required attributes" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_network_interface(:test, {
          subnet_id: "subnet-12345678"
        })
      end

      result = synthesizer.synthesis

      expect(result).to have_key("resource")
      expect(result["resource"]).to have_key("aws_network_interface")
      expect(result["resource"]["aws_network_interface"]).to have_key("test")

      config = result["resource"]["aws_network_interface"]["test"]
      expect(config["subnet_id"]).to eq("subnet-12345678")
    end

    it "generates terraform JSON with security groups" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_network_interface(:with_sgs, {
          subnet_id: "subnet-12345678",
          security_groups: ["sg-aaa", "sg-bbb"]
        })
      end

      result = synthesizer.synthesis
      config = result["resource"]["aws_network_interface"]["with_sgs"]

      expect(config["security_groups"]).to eq(["sg-aaa", "sg-bbb"])
    end

    it "generates terraform JSON with private IPs" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_network_interface(:with_ips, {
          subnet_id: "subnet-12345678",
          private_ips: ["10.0.0.10", "10.0.0.11"]
        })
      end

      result = synthesizer.synthesis
      config = result["resource"]["aws_network_interface"]["with_ips"]

      expect(config["private_ips"]).to eq(["10.0.0.10", "10.0.0.11"])
    end

    it "supports description and source_dest_check" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_network_interface(:detailed, {
          subnet_id: "subnet-12345678",
          description: "My network interface",
          source_dest_check: false
        })
      end

      result = synthesizer.synthesis
      config = result["resource"]["aws_network_interface"]["detailed"]

      expect(config["description"]).to eq("My network interface")
      expect(config["source_dest_check"]).to eq(false)
    end

    it "supports interface type" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_network_interface(:efa, {
          subnet_id: "subnet-12345678",
          interface_type: "efa"
        })
      end

      result = synthesizer.synthesis
      config = result["resource"]["aws_network_interface"]["efa"]

      expect(config["interface_type"]).to eq("efa")
    end

    it "includes tags when provided" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_network_interface(:tagged, {
          subnet_id: "subnet-12345678",
          tags: { Name: "test-eni", Environment: "test" }
        })
      end

      result = synthesizer.synthesis
      config = result["resource"]["aws_network_interface"]["tagged"]

      expect(config).to have_key("tags")
      expect(config["tags"]["Name"]).to eq("test-eni")
      expect(config["tags"]["Environment"]).to eq("test")
    end
  end

  describe "resource reference" do
    it "returns a ResourceReference with correct outputs" do
      ref = nil
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        ref = aws_network_interface(:test_ref, {
          subnet_id: "subnet-12345678"
        })
      end

      expect(ref).to be_a(Pangea::Resources::ResourceReference)
      expect(ref.outputs[:id]).to eq("${aws_network_interface.test_ref.id}")
      expect(ref.outputs[:arn]).to eq("${aws_network_interface.test_ref.arn}")
      expect(ref.outputs[:private_ip]).to eq("${aws_network_interface.test_ref.private_ip}")
      expect(ref.outputs[:mac_address]).to eq("${aws_network_interface.test_ref.mac_address}")
      expect(ref.outputs[:subnet_id]).to eq("${aws_network_interface.test_ref.subnet_id}")
    end

    it "provides correct computed properties" do
      ref = nil
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        ref = aws_network_interface(:test_ref, {
          subnet_id: "subnet-12345678",
          interface_type: "efa"
        })
      end

      expect(ref.computed_properties[:interface_type_name]).to eq("Elastic Fabric Adapter")
      expect(ref.computed_properties[:attached_at_creation]).to eq(false)
    end
  end

  describe "terraform validation" do
    it "produces valid terraform structure" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_network_interface(:test, {
          subnet_id: "subnet-12345678"
        })
      end

      result = synthesizer.synthesis

      expect(result).to be_a(Hash)
      expect(result["resource"]).to be_a(Hash)
      expect(result["resource"]["aws_network_interface"]).to be_a(Hash)
      expect(result["resource"]["aws_network_interface"]["test"]).to be_a(Hash)
    end

    it "rejects specifying both private_ips and private_ips_count" do
      expect {
        Pangea::Resources::AWS::Types::NetworkInterfaceAttributes.new(
          subnet_id: "subnet-12345678",
          private_ips: ["10.0.0.10"],
          private_ips_count: 2
        )
      }.to raise_error(Dry::Struct::Error, /Cannot specify both.*private_ips.*private_ips_count/)
    end

    it "rejects specifying both ipv6_addresses and ipv6_address_count" do
      expect {
        Pangea::Resources::AWS::Types::NetworkInterfaceAttributes.new(
          subnet_id: "subnet-12345678",
          ipv6_addresses: ["2001:db8::1"],
          ipv6_address_count: 2
        )
      }.to raise_error(Dry::Struct::Error, /Cannot specify both.*ipv6_addresses.*ipv6_address_count/)
    end

    it "rejects attachment missing required keys" do
      expect {
        Pangea::Resources::AWS::Types::NetworkInterfaceAttributes.new(
          subnet_id: "subnet-12345678",
          attachment: { instance: "i-12345678" }
        )
      }.to raise_error(Dry::Struct::Error, /Attachment requires/)
    end
  end
end
