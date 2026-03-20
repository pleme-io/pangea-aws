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
require 'pangea/resources/aws_eks_access_entry/resource'

RSpec.describe "aws_eks_access_entry synthesis" do
  include Pangea::Resources::AWS

  let(:synthesizer) { TerraformSynthesizer.new }

  describe "terraform generation" do
    it "generates valid terraform JSON with required attributes" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_eks_access_entry(:test, {
          cluster_name: "test-cluster",
          principal_arn: "arn:aws:iam::123456789012:role/my-role"
        })
      end

      result = synthesizer.synthesis

      expect(result).to have_key("resource")
      expect(result["resource"]).to have_key("aws_eks_access_entry")
      expect(result["resource"]["aws_eks_access_entry"]).to have_key("test")

      config = result["resource"]["aws_eks_access_entry"]["test"]
      expect(config["cluster_name"]).to eq("test-cluster")
      expect(config["principal_arn"]).to eq("arn:aws:iam::123456789012:role/my-role")
    end

    it "includes tags when provided" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_eks_access_entry(:test, {
          cluster_name: "test-cluster",
          principal_arn: "arn:aws:iam::123456789012:role/my-role",
          tags: { "Name" => "test-access", "Environment" => "test" }
        })
      end

      result = synthesizer.synthesis
      config = result["resource"]["aws_eks_access_entry"]["test"]

      expect(config).to have_key("tags")
      expect(config["tags"]["Name"]).to eq("test-access")
      expect(config["tags"]["Environment"]).to eq("test")
    end

    it "supports kubernetes groups" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_eks_access_entry(:test, {
          cluster_name: "test-cluster",
          principal_arn: "arn:aws:iam::123456789012:role/my-role",
          kubernetes_groups: ["system:masters"]
        })
      end

      result = synthesizer.synthesis
      config = result["resource"]["aws_eks_access_entry"]["test"]

      expect(config["kubernetes_groups"]).to eq(["system:masters"])
    end

    it "supports access entry type" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_eks_access_entry(:test, {
          cluster_name: "test-cluster",
          principal_arn: "arn:aws:iam::123456789012:role/my-role",
          type: "EC2_LINUX"
        })
      end

      result = synthesizer.synthesis
      config = result["resource"]["aws_eks_access_entry"]["test"]

      expect(config["type"]).to eq("EC2_LINUX")
    end
  end

  describe "terraform validation" do
    it "produces valid terraform structure" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_eks_access_entry(:test, {
          cluster_name: "test-cluster",
          principal_arn: "arn:aws:iam::123456789012:role/my-role"
        })
      end

      result = synthesizer.synthesis

      expect(result).to be_a(Hash)
      expect(result["resource"]).to be_a(Hash)
      expect(result["resource"]["aws_eks_access_entry"]).to be_a(Hash)
      expect(result["resource"]["aws_eks_access_entry"]["test"]).to be_a(Hash)
    end

    it "rejects invalid access entry type" do
      expect {
        synthesizer.instance_eval do
          extend Pangea::Resources::AWS
          aws_eks_access_entry(:test, {
            cluster_name: "test-cluster",
            principal_arn: "arn:aws:iam::123456789012:role/my-role",
            type: "INVALID_TYPE"
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
        ref = aws_eks_access_entry(:test, {
          cluster_name: "test-cluster",
          principal_arn: "arn:aws:iam::123456789012:role/my-role"
        })
      end

      expect(ref).to be_a(Pangea::Resources::ResourceReference)
      expect(ref.id).to eq("${aws_eks_access_entry.test.id}")
      expect(ref.outputs[:access_entry_arn]).to eq("${aws_eks_access_entry.test.access_entry_arn}")
      expect(ref.outputs[:cluster_name]).to eq("${aws_eks_access_entry.test.cluster_name}")
      expect(ref.outputs[:principal_arn]).to eq("${aws_eks_access_entry.test.principal_arn}")
    end

    it "provides computed properties" do
      ref = nil
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        ref = aws_eks_access_entry(:test, {
          cluster_name: "test-cluster",
          principal_arn: "arn:aws:iam::123456789012:role/my-role",
          kubernetes_groups: ["system:masters"],
          type: "STANDARD"
        })
      end

      expect(ref.principal_name).to eq("my-role")
      expect(ref.principal_type).to eq("role")
      expect(ref.account_id).to eq("123456789012")
      expect(ref.has_kubernetes_groups).to eq(true)
      expect(ref.standard_type).to eq(true)
      expect(ref.fargate_type).to eq(false)
      expect(ref.kubernetes_groups_count).to eq(1)
    end
  end
end
