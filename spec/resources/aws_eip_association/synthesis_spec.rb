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
require 'pangea/resources/aws_eip_association/resource'

RSpec.describe "aws_eip_association synthesis" do
  include Pangea::Resources::AWS

  let(:synthesizer) { TerraformSynthesizer.new }

  describe "terraform generation" do
    it "generates valid terraform JSON with allocation_id and instance_id" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_eip_association(:test, {
          allocation_id: "eipalloc-12345678",
          instance_id: "i-12345678"
        })
      end

      result = synthesizer.synthesis

      expect(result).to have_key("resource")
      expect(result["resource"]).to have_key("aws_eip_association")
      expect(result["resource"]["aws_eip_association"]).to have_key("test")

      config = result["resource"]["aws_eip_association"]["test"]
      expect(config["allocation_id"]).to eq("eipalloc-12345678")
      expect(config["instance_id"]).to eq("i-12345678")
    end

    it "generates valid terraform JSON with public_ip" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_eip_association(:public_ip_test, {
          public_ip: "203.0.113.1",
          instance_id: "i-12345678"
        })
      end

      result = synthesizer.synthesis
      config = result["resource"]["aws_eip_association"]["public_ip_test"]

      expect(config["public_ip"]).to eq("203.0.113.1")
      expect(config["instance_id"]).to eq("i-12345678")
    end

    it "generates valid terraform JSON with network_interface_id" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_eip_association(:eni_test, {
          allocation_id: "eipalloc-12345678",
          network_interface_id: "eni-12345678",
          private_ip_address: "10.0.0.10"
        })
      end

      result = synthesizer.synthesis
      config = result["resource"]["aws_eip_association"]["eni_test"]

      expect(config["allocation_id"]).to eq("eipalloc-12345678")
      expect(config["network_interface_id"]).to eq("eni-12345678")
      expect(config["private_ip_address"]).to eq("10.0.0.10")
    end

    it "supports allow_reassociation" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_eip_association(:reassoc, {
          allocation_id: "eipalloc-12345678",
          instance_id: "i-12345678",
          allow_reassociation: true
        })
      end

      result = synthesizer.synthesis
      config = result["resource"]["aws_eip_association"]["reassoc"]

      expect(config["allow_reassociation"]).to eq(true)
    end

    it "includes tags when provided" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_eip_association(:tagged, {
          allocation_id: "eipalloc-12345678",
          instance_id: "i-12345678",
          tags: { Name: "test-eip-assoc", Environment: "test" }
        })
      end

      result = synthesizer.synthesis
      config = result["resource"]["aws_eip_association"]["tagged"]

      expect(config).to have_key("tags")
      expect(config["tags"]["Name"]).to eq("test-eip-assoc")
      expect(config["tags"]["Environment"]).to eq("test")
    end
  end

  describe "resource reference" do
    it "returns a ResourceReference with correct outputs" do
      ref = nil
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        ref = aws_eip_association(:test_ref, {
          allocation_id: "eipalloc-12345678",
          instance_id: "i-12345678"
        })
      end

      expect(ref).to be_a(Pangea::Resources::ResourceReference)
      expect(ref.outputs[:id]).to eq("${aws_eip_association.test_ref.id}")
      expect(ref.outputs[:allocation_id]).to eq("${aws_eip_association.test_ref.allocation_id}")
      expect(ref.outputs[:instance_id]).to eq("${aws_eip_association.test_ref.instance_id}")
      expect(ref.outputs[:network_interface_id]).to eq("${aws_eip_association.test_ref.network_interface_id}")
      expect(ref.outputs[:public_ip]).to eq("${aws_eip_association.test_ref.public_ip}")
    end
  end

  describe "terraform validation" do
    it "produces valid terraform structure" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_eip_association(:test, {
          allocation_id: "eipalloc-12345678",
          instance_id: "i-12345678"
        })
      end

      result = synthesizer.synthesis

      expect(result).to be_a(Hash)
      expect(result["resource"]).to be_a(Hash)
      expect(result["resource"]["aws_eip_association"]).to be_a(Hash)
      expect(result["resource"]["aws_eip_association"]["test"]).to be_a(Hash)
    end

    it "rejects missing allocation_id and public_ip" do
      expect {
        Pangea::Resources::AWS::Types::EipAssociationAttributes.new(
          instance_id: "i-12345678"
        )
      }.to raise_error(Dry::Struct::Error, /Either.*allocation_id.*public_ip/)
    end

    it "rejects specifying both instance_id and network_interface_id" do
      expect {
        Pangea::Resources::AWS::Types::EipAssociationAttributes.new(
          allocation_id: "eipalloc-12345678",
          instance_id: "i-12345678",
          network_interface_id: "eni-12345678"
        )
      }.to raise_error(Dry::Struct::Error, /Cannot specify both.*instance_id.*network_interface_id/)
    end

    it "rejects private_ip_address without network_interface_id" do
      expect {
        Pangea::Resources::AWS::Types::EipAssociationAttributes.new(
          allocation_id: "eipalloc-12345678",
          instance_id: "i-12345678",
          private_ip_address: "10.0.0.10"
        )
      }.to raise_error(Dry::Struct::Error, /private_ip_address.*requires.*network_interface_id/)
    end
  end
end
