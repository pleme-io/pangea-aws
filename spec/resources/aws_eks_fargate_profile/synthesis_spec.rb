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
require 'pangea/resources/aws_eks_fargate_profile/resource'

RSpec.describe "aws_eks_fargate_profile synthesis" do
  include Pangea::Resources::AWS

  let(:synthesizer) { TerraformSynthesizer.new }

  describe "terraform generation" do
    it "generates valid terraform JSON with required attributes" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_eks_fargate_profile(:test, {
          cluster_name: "test-cluster",
          pod_execution_role_arn: "arn:aws:iam::123456789012:role/fargate-role",
          selectors: [
            { namespace: "default" }
          ]
        })
      end

      result = synthesizer.synthesis

      expect(result).to have_key("resource")
      expect(result["resource"]).to have_key("aws_eks_fargate_profile")
      expect(result["resource"]["aws_eks_fargate_profile"]).to have_key("test")

      config = result["resource"]["aws_eks_fargate_profile"]["test"]
      expect(config["cluster_name"]).to eq("test-cluster")
      expect(config["pod_execution_role_arn"]).to eq("arn:aws:iam::123456789012:role/fargate-role")
    end

    it "includes tags when provided" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_eks_fargate_profile(:test, {
          cluster_name: "test-cluster",
          pod_execution_role_arn: "arn:aws:iam::123456789012:role/fargate-role",
          selectors: [{ namespace: "default" }],
          tags: { Name: "test-profile", Environment: "test" }
        })
      end

      result = synthesizer.synthesis
      config = result["resource"]["aws_eks_fargate_profile"]["test"]

      expect(config).to have_key("tags")
      expect(config["tags"]["Name"]).to eq("test-profile")
    end

    it "supports multiple selectors with labels" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_eks_fargate_profile(:test, {
          cluster_name: "test-cluster",
          pod_execution_role_arn: "arn:aws:iam::123456789012:role/fargate-role",
          selectors: [
            { namespace: "production", labels: { tier: "web" } },
            { namespace: "staging", labels: { tier: "web" } }
          ]
        })
      end

      result = synthesizer.synthesis
      config = result["resource"]["aws_eks_fargate_profile"]["test"]

      expect(config).to have_key("selector")
    end

    it "supports subnet IDs" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_eks_fargate_profile(:test, {
          cluster_name: "test-cluster",
          pod_execution_role_arn: "arn:aws:iam::123456789012:role/fargate-role",
          selectors: [{ namespace: "default" }],
          subnet_ids: ["subnet-12345", "subnet-67890"]
        })
      end

      result = synthesizer.synthesis
      config = result["resource"]["aws_eks_fargate_profile"]["test"]

      expect(config["subnet_ids"]).to eq(["subnet-12345", "subnet-67890"])
    end
  end

  describe "terraform validation" do
    it "produces valid terraform structure" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_eks_fargate_profile(:test, {
          cluster_name: "test-cluster",
          pod_execution_role_arn: "arn:aws:iam::123456789012:role/fargate-role",
          selectors: [{ namespace: "default" }]
        })
      end

      result = synthesizer.synthesis

      expect(result).to be_a(Hash)
      expect(result["resource"]).to be_a(Hash)
      expect(result["resource"]["aws_eks_fargate_profile"]).to be_a(Hash)
      expect(result["resource"]["aws_eks_fargate_profile"]["test"]).to be_a(Hash)
    end

    it "rejects duplicate namespace selectors without labels" do
      expect {
        synthesizer.instance_eval do
          extend Pangea::Resources::AWS
          aws_eks_fargate_profile(:test, {
            cluster_name: "test-cluster",
            pod_execution_role_arn: "arn:aws:iam::123456789012:role/fargate-role",
            selectors: [
              { namespace: "default" },
              { namespace: "default" }
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
        ref = aws_eks_fargate_profile(:test, {
          cluster_name: "test-cluster",
          pod_execution_role_arn: "arn:aws:iam::123456789012:role/fargate-role",
          selectors: [{ namespace: "default" }]
        })
      end

      expect(ref).to be_a(Pangea::Resources::ResourceReference)
      expect(ref.id).to eq("${aws_eks_fargate_profile.test.id}")
      expect(ref.arn).to eq("${aws_eks_fargate_profile.test.arn}")
      expect(ref.outputs[:cluster_name]).to eq("${aws_eks_fargate_profile.test.cluster_name}")
      expect(ref.outputs[:pod_execution_role_arn]).to eq("${aws_eks_fargate_profile.test.pod_execution_role_arn}")
    end

    it "provides computed properties" do
      ref = nil
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        ref = aws_eks_fargate_profile(:test, {
          cluster_name: "test-cluster",
          pod_execution_role_arn: "arn:aws:iam::123456789012:role/fargate-role",
          selectors: [
            { namespace: "production", labels: { tier: "web" } },
            { namespace: "staging" }
          ]
        })
      end

      expect(ref.namespaces).to contain_exactly("production", "staging")
      expect(ref.has_labels).to eq(true)
      expect(ref.selector_count).to eq(2)
    end
  end
end
