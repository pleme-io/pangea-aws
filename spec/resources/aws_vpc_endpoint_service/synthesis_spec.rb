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
require 'pangea/resources/aws_vpc_endpoint_service/resource'

RSpec.describe "aws_vpc_endpoint_service synthesis" do
  include Pangea::Resources::AWS

  let(:synthesizer) { TerraformSynthesizer.new }
  let(:nlb_arn) { "arn:aws:elasticloadbalancing:us-east-1:123456789012:loadbalancer/net/my-nlb/1234567890" }
  let(:gwlb_arn) { "arn:aws:elasticloadbalancing:us-east-1:123456789012:loadbalancer/gwy/my-gwlb/1234567890" }

  describe "terraform generation" do
    it "generates valid terraform JSON with NLB" do
      arn = nlb_arn
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_vpc_endpoint_service(:test, {
          acceptance_required: true,
          network_load_balancer_arns: [arn]
        })
      end

      result = synthesizer.synthesis

      expect(result).to have_key("resource")
      expect(result["resource"]).to have_key("aws_vpc_endpoint_service")
      expect(result["resource"]["aws_vpc_endpoint_service"]).to have_key("test")

      config = result["resource"]["aws_vpc_endpoint_service"]["test"]
      expect(config["acceptance_required"]).to eq(true)
      expect(config["network_load_balancer_arns"]).to include(arn)
    end

    it "generates valid terraform JSON with GWLB" do
      arn = gwlb_arn
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_vpc_endpoint_service(:gwlb_test, {
          acceptance_required: false,
          gateway_load_balancer_arns: [arn]
        })
      end

      result = synthesizer.synthesis
      config = result["resource"]["aws_vpc_endpoint_service"]["gwlb_test"]

      expect(config["acceptance_required"]).to eq(false)
      expect(config["gateway_load_balancer_arns"]).to include(arn)
    end

    it "includes tags when provided" do
      arn = nlb_arn
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_vpc_endpoint_service(:tagged, {
          acceptance_required: true,
          network_load_balancer_arns: [arn],
          tags: { Name: "test-endpoint-svc", Environment: "test" }
        })
      end

      result = synthesizer.synthesis
      config = result["resource"]["aws_vpc_endpoint_service"]["tagged"]

      expect(config).to have_key("tags")
      expect(config["tags"]["Name"]).to eq("test-endpoint-svc")
      expect(config["tags"]["Environment"]).to eq("test")
    end

    it "supports private DNS name" do
      arn = nlb_arn
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_vpc_endpoint_service(:with_dns, {
          acceptance_required: true,
          network_load_balancer_arns: [arn],
          private_dns_name: "my.service.example.com"
        })
      end

      result = synthesizer.synthesis
      config = result["resource"]["aws_vpc_endpoint_service"]["with_dns"]

      expect(config["private_dns_name"]).to eq("my.service.example.com")
    end

    it "supports IP address types" do
      arn = nlb_arn
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_vpc_endpoint_service(:with_ip_types, {
          acceptance_required: true,
          network_load_balancer_arns: [arn],
          supported_ip_address_types: ["ipv4", "ipv6"]
        })
      end

      result = synthesizer.synthesis
      config = result["resource"]["aws_vpc_endpoint_service"]["with_ip_types"]

      expect(config["supported_ip_address_types"]).to eq(["ipv4", "ipv6"])
    end
  end

  describe "resource reference" do
    it "returns a ResourceReference with correct outputs" do
      ref = nil
      arn = nlb_arn
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        ref = aws_vpc_endpoint_service(:test_ref, {
          acceptance_required: true,
          network_load_balancer_arns: [arn]
        })
      end

      expect(ref).to be_a(Pangea::Resources::ResourceReference)
      expect(ref.outputs[:id]).to eq("${aws_vpc_endpoint_service.test_ref.id}")
      expect(ref.outputs[:arn]).to eq("${aws_vpc_endpoint_service.test_ref.arn}")
      expect(ref.outputs[:service_name]).to eq("${aws_vpc_endpoint_service.test_ref.service_name}")
      expect(ref.outputs[:state]).to eq("${aws_vpc_endpoint_service.test_ref.state}")
    end

    it "provides computed properties" do
      ref = nil
      arn = nlb_arn
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        ref = aws_vpc_endpoint_service(:test_ref, {
          acceptance_required: true,
          network_load_balancer_arns: [arn]
        })
      end

      expect(ref.computed_properties[:uses_network_load_balancers]).to eq(true)
      expect(ref.computed_properties[:uses_gateway_load_balancers]).to eq(false)
      expect(ref.computed_properties[:load_balancer_type]).to eq(:network)
    end
  end

  describe "terraform validation" do
    it "produces valid terraform structure" do
      arn = nlb_arn
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_vpc_endpoint_service(:test, {
          acceptance_required: true,
          network_load_balancer_arns: [arn]
        })
      end

      result = synthesizer.synthesis

      expect(result).to be_a(Hash)
      expect(result["resource"]).to be_a(Hash)
      expect(result["resource"]["aws_vpc_endpoint_service"]).to be_a(Hash)
      expect(result["resource"]["aws_vpc_endpoint_service"]["test"]).to be_a(Hash)
    end

    it "rejects missing load balancer ARNs" do
      expect {
        Pangea::Resources::AWS::Types::VpcEndpointServiceAttributes.new(
          acceptance_required: true
        )
      }.to raise_error(Dry::Struct::Error, /Must specify either/)
    end

    it "rejects specifying both NLB and GWLB ARNs" do
      expect {
        Pangea::Resources::AWS::Types::VpcEndpointServiceAttributes.new(
          acceptance_required: true,
          network_load_balancer_arns: [nlb_arn],
          gateway_load_balancer_arns: [gwlb_arn]
        )
      }.to raise_error(Dry::Struct::Error, /Cannot specify both/)
    end

    it "rejects invalid load balancer ARN format" do
      expect {
        Pangea::Resources::AWS::Types::VpcEndpointServiceAttributes.new(
          acceptance_required: true,
          network_load_balancer_arns: ["invalid-arn"]
        )
      }.to raise_error(Dry::Struct::Error, /Invalid load balancer ARN/)
    end
  end
end
