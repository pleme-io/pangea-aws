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
require 'pangea/resources/aws_ecs_cluster_capacity_providers/resource'

RSpec.describe "aws_ecs_cluster_capacity_providers synthesis" do
  include Pangea::Resources::AWS

  let(:synthesizer) { TerraformSynthesizer.new }

  describe "terraform generation" do
    it "generates valid terraform JSON with Fargate providers" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_ecs_cluster_capacity_providers(:test, {
          cluster_name: "test-cluster",
          capacity_providers: ["FARGATE", "FARGATE_SPOT"],
          default_capacity_provider_strategy: [
            { capacity_provider: "FARGATE", weight: 1, base: 1 },
            { capacity_provider: "FARGATE_SPOT", weight: 4 }
          ]
        })
      end

      result = synthesizer.synthesis

      expect(result).to have_key("resource")
      expect(result["resource"]).to have_key("aws_ecs_cluster_capacity_providers")
      expect(result["resource"]["aws_ecs_cluster_capacity_providers"]).to have_key("test")

      config = result["resource"]["aws_ecs_cluster_capacity_providers"]["test"]
      expect(config["cluster_name"]).to eq("test-cluster")
      expect(config["capacity_providers"]).to eq(["FARGATE", "FARGATE_SPOT"])
    end

    it "supports custom capacity provider names" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_ecs_cluster_capacity_providers(:test, {
          cluster_name: "test-cluster",
          capacity_providers: ["my-custom-provider"],
          default_capacity_provider_strategy: [
            { capacity_provider: "my-custom-provider", weight: 1 }
          ]
        })
      end

      result = synthesizer.synthesis
      config = result["resource"]["aws_ecs_cluster_capacity_providers"]["test"]

      expect(config["capacity_providers"]).to eq(["my-custom-provider"])
    end
  end

  describe "terraform validation" do
    it "produces valid terraform structure" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_ecs_cluster_capacity_providers(:test, {
          cluster_name: "test-cluster",
          capacity_providers: ["FARGATE"],
          default_capacity_provider_strategy: [
            { capacity_provider: "FARGATE", weight: 1 }
          ]
        })
      end

      result = synthesizer.synthesis

      expect(result).to be_a(Hash)
      expect(result["resource"]).to be_a(Hash)
      expect(result["resource"]["aws_ecs_cluster_capacity_providers"]).to be_a(Hash)
      expect(result["resource"]["aws_ecs_cluster_capacity_providers"]["test"]).to be_a(Hash)
    end

    it "rejects strategy referencing undefined capacity provider" do
      expect {
        synthesizer.instance_eval do
          extend Pangea::Resources::AWS
          aws_ecs_cluster_capacity_providers(:test, {
            cluster_name: "test-cluster",
            capacity_providers: ["FARGATE"],
            default_capacity_provider_strategy: [
              { capacity_provider: "UNDEFINED_PROVIDER", weight: 1 }
            ]
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
        ref = aws_ecs_cluster_capacity_providers(:test, {
          cluster_name: "test-cluster",
          capacity_providers: ["FARGATE"],
          default_capacity_provider_strategy: [
            { capacity_provider: "FARGATE", weight: 1 }
          ]
        })
      end

      expect(ref).to be_a(Pangea::Resources::ResourceReference)
      expect(ref.id).to eq("${aws_ecs_cluster_capacity_providers.test.id}")
      expect(ref.outputs[:cluster_name]).to eq("${aws_ecs_cluster_capacity_providers.test.cluster_name}")
    end

    it "provides computed properties" do
      ref = nil
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        ref = aws_ecs_cluster_capacity_providers(:test, {
          cluster_name: "test-cluster",
          capacity_providers: ["FARGATE", "FARGATE_SPOT"],
          default_capacity_provider_strategy: [
            { capacity_provider: "FARGATE", weight: 1, base: 1 },
            { capacity_provider: "FARGATE_SPOT", weight: 4 }
          ]
        })
      end

      expect(ref.using_fargate).to eq(true)
      expect(ref.provider_count).to eq(2)
      expect(ref.has_default_strategy).to eq(true)
      expect(ref.spot_prioritized).to eq(true)
      expect(ref.primary_capacity_provider).to eq("FARGATE")
    end
  end
end
