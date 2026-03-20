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
require 'pangea/resources/aws_ecs_capacity_provider/resource'

RSpec.describe "aws_ecs_capacity_provider synthesis" do
  include Pangea::Resources::AWS

  let(:synthesizer) { TerraformSynthesizer.new }

  describe "terraform generation" do
    it "generates valid terraform JSON with name only" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_ecs_capacity_provider(:test, {
          name: "test-provider"
        })
      end

      result = synthesizer.synthesis

      expect(result).to have_key("resource")
      expect(result["resource"]).to have_key("aws_ecs_capacity_provider")
      expect(result["resource"]["aws_ecs_capacity_provider"]).to have_key("test")

      config = result["resource"]["aws_ecs_capacity_provider"]["test"]
      expect(config["name"]).to eq("test-provider")
    end

    it "includes tags when provided" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_ecs_capacity_provider(:test, {
          name: "test-provider",
          tags: { "Name" => "test-provider", "Environment" => "test" }
        })
      end

      result = synthesizer.synthesis
      config = result["resource"]["aws_ecs_capacity_provider"]["test"]

      expect(config).to have_key("tags")
      expect(config["tags"]["Name"]).to eq("test-provider")
      expect(config["tags"]["Environment"]).to eq("test")
    end

    it "supports auto scaling group provider configuration" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_ecs_capacity_provider(:test, {
          name: "ec2-provider",
          auto_scaling_group_provider: {
            auto_scaling_group_arn: "arn:aws:autoscaling:us-east-1:123456789012:autoScalingGroup:12345678-1234-1234-1234-123456789012:autoScalingGroupName/my-asg",
            managed_scaling: {
              status: "ENABLED",
              target_capacity: 80
            },
            managed_termination_protection: "ENABLED"
          }
        })
      end

      result = synthesizer.synthesis
      config = result["resource"]["aws_ecs_capacity_provider"]["test"]

      expect(config).to have_key("auto_scaling_group_provider")
    end
  end

  describe "terraform validation" do
    it "produces valid terraform structure" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_ecs_capacity_provider(:test, { name: "test-provider" })
      end

      result = synthesizer.synthesis

      expect(result).to be_a(Hash)
      expect(result["resource"]).to be_a(Hash)
      expect(result["resource"]["aws_ecs_capacity_provider"]).to be_a(Hash)
      expect(result["resource"]["aws_ecs_capacity_provider"]["test"]).to be_a(Hash)

      config = result["resource"]["aws_ecs_capacity_provider"]["test"]
      expect(config).to have_key("name")
      expect(config["name"]).to be_a(String)
    end

    it "rejects invalid capacity provider names" do
      expect {
        synthesizer.instance_eval do
          extend Pangea::Resources::AWS
          aws_ecs_capacity_provider(:test, {
            name: "invalid name with spaces!"
          })
        end
      }.to raise_error(Dry::Struct::Error)
    end
  end

  describe "resource references" do
    it "returns a resource reference with outputs" do
      ref = nil
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        ref = aws_ecs_capacity_provider(:test, { name: "test-provider" })
      end

      expect(ref).to be_a(Pangea::Resources::ResourceReference)
      expect(ref.id).to eq("${aws_ecs_capacity_provider.test.id}")
      expect(ref.arn).to eq("${aws_ecs_capacity_provider.test.arn}")
      expect(ref.outputs[:name]).to eq("${aws_ecs_capacity_provider.test.name}")
    end

    it "provides computed properties for fargate provider" do
      ref = nil
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        ref = aws_ecs_capacity_provider(:test, { name: "fargate-provider" })
      end

      expect(ref.fargate_provider).to eq(true)
      expect(ref.ec2_provider).to eq(false)
      expect(ref.has_auto_scaling_group).to eq(false)
    end

    it "provides computed properties for ec2 provider" do
      ref = nil
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        ref = aws_ecs_capacity_provider(:test, {
          name: "ec2-provider",
          auto_scaling_group_provider: {
            auto_scaling_group_arn: "arn:aws:autoscaling:us-east-1:123456789012:autoScalingGroup:12345678-1234-1234-1234-123456789012:autoScalingGroupName/my-asg",
            managed_scaling: {
              status: "ENABLED",
              target_capacity: 80
            },
            managed_termination_protection: "ENABLED"
          }
        })
      end

      expect(ref.fargate_provider).to eq(false)
      expect(ref.ec2_provider).to eq(true)
      expect(ref.has_auto_scaling_group).to eq(true)
      expect(ref.managed_scaling_enabled).to eq(true)
      expect(ref.managed_termination_protection_enabled).to eq(true)
      expect(ref.target_capacity_percentage).to eq(80)
    end
  end
end
