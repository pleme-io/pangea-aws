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
require 'pangea/resources/aws_vpc_endpoint_connection_notification/resource'

RSpec.describe "aws_vpc_endpoint_connection_notification synthesis" do
  include Pangea::Resources::AWS

  let(:synthesizer) { TerraformSynthesizer.new }

  describe "terraform generation" do
    it "generates valid terraform JSON with required attributes" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_vpc_endpoint_connection_notification(:test, {
          vpc_endpoint_service_id: "vpce-svc-12345678",
          connection_notification_arn: "arn:aws:sns:us-east-1:123456789012:my-topic",
          connection_events: ["Accept", "Reject"]
        })
      end

      result = synthesizer.synthesis

      expect(result).to have_key("resource")
      expect(result["resource"]).to have_key("aws_vpc_endpoint_connection_notification")
      expect(result["resource"]["aws_vpc_endpoint_connection_notification"]).to have_key("test")

      config = result["resource"]["aws_vpc_endpoint_connection_notification"]["test"]
      expect(config["vpc_endpoint_service_id"]).to eq("vpce-svc-12345678")
      expect(config["connection_notification_arn"]).to eq("arn:aws:sns:us-east-1:123456789012:my-topic")
      expect(config["connection_events"]).to eq(["Accept", "Reject"])
    end

    it "includes tags when provided" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_vpc_endpoint_connection_notification(:tagged, {
          vpc_endpoint_service_id: "vpce-svc-12345678",
          connection_notification_arn: "arn:aws:sns:us-east-1:123456789012:my-topic",
          connection_events: ["Accept"],
          tags: { Name: "test-notification", Environment: "test" }
        })
      end

      result = synthesizer.synthesis
      config = result["resource"]["aws_vpc_endpoint_connection_notification"]["tagged"]

      expect(config).to have_key("tags")
      expect(config["tags"]["Name"]).to eq("test-notification")
      expect(config["tags"]["Environment"]).to eq("test")
    end

    it "supports all valid connection events" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_vpc_endpoint_connection_notification(:all_events, {
          vpc_endpoint_service_id: "vpce-svc-12345678",
          connection_notification_arn: "arn:aws:sns:us-east-1:123456789012:my-topic",
          connection_events: ["Accept", "Connect", "Delete", "Reject"]
        })
      end

      result = synthesizer.synthesis
      config = result["resource"]["aws_vpc_endpoint_connection_notification"]["all_events"]
      expect(config["connection_events"]).to eq(["Accept", "Connect", "Delete", "Reject"])
    end
  end

  describe "resource reference" do
    it "returns a ResourceReference with correct outputs" do
      ref = nil
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        ref = aws_vpc_endpoint_connection_notification(:test_ref, {
          vpc_endpoint_service_id: "vpce-svc-12345678",
          connection_notification_arn: "arn:aws:sns:us-east-1:123456789012:my-topic",
          connection_events: ["Accept"]
        })
      end

      expect(ref).to be_a(Pangea::Resources::ResourceReference)
      expect(ref.outputs[:id]).to eq("${aws_vpc_endpoint_connection_notification.test_ref.id}")
      expect(ref.outputs[:vpc_endpoint_service_id]).to eq("${aws_vpc_endpoint_connection_notification.test_ref.vpc_endpoint_service_id}")
      expect(ref.outputs[:connection_notification_arn]).to eq("${aws_vpc_endpoint_connection_notification.test_ref.connection_notification_arn}")
      expect(ref.outputs[:state]).to eq("${aws_vpc_endpoint_connection_notification.test_ref.state}")
    end
  end

  describe "terraform validation" do
    it "produces valid terraform structure" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_vpc_endpoint_connection_notification(:test, {
          vpc_endpoint_service_id: "vpce-svc-12345678",
          connection_notification_arn: "arn:aws:sns:us-east-1:123456789012:my-topic",
          connection_events: ["Accept"]
        })
      end

      result = synthesizer.synthesis

      expect(result).to be_a(Hash)
      expect(result["resource"]).to be_a(Hash)
      expect(result["resource"]["aws_vpc_endpoint_connection_notification"]).to be_a(Hash)
      expect(result["resource"]["aws_vpc_endpoint_connection_notification"]["test"]).to be_a(Hash)
    end

    it "rejects invalid connection events" do
      expect {
        Pangea::Resources::AWS::Types::VpcEndpointConnectionNotificationAttributes.new(
          connection_events: ["InvalidEvent"]
        )
      }.to raise_error(Dry::Struct::Error)
    end
  end
end
