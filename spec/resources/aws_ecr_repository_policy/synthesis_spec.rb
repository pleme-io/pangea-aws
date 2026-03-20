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
require 'pangea/resources/aws_ecr_repository_policy/resource'
require 'json'

RSpec.describe "aws_ecr_repository_policy synthesis" do
  include Pangea::Resources::AWS

  let(:synthesizer) { TerraformSynthesizer.new }

  let(:valid_policy) do
    JSON.generate({
      "Version" => "2012-10-17",
      "Statement" => [
        {
          "Effect" => "Allow",
          "Principal" => {
            "AWS" => "arn:aws:iam::123456789012:root"
          },
          "Action" => [
            "ecr:GetDownloadUrlForLayer",
            "ecr:BatchGetImage",
            "ecr:BatchCheckLayerAvailability"
          ]
        }
      ]
    })
  end

  describe "terraform generation" do
    it "generates valid terraform JSON" do
      policy = valid_policy
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_ecr_repository_policy(:test, {
          repository: "my-repo",
          policy: policy
        })
      end

      result = synthesizer.synthesis

      expect(result).to have_key("resource")
      expect(result["resource"]).to have_key("aws_ecr_repository_policy")
      expect(result["resource"]["aws_ecr_repository_policy"]).to have_key("test")

      config = result["resource"]["aws_ecr_repository_policy"]["test"]
      expect(config["repository"]).to eq("my-repo")
      expect(config["policy"]).to eq(policy)
    end

    it "supports terraform references for repository" do
      policy = valid_policy
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_ecr_repository_policy(:test, {
          repository: "${aws_ecr_repository.main.name}",
          policy: policy
        })
      end

      result = synthesizer.synthesis
      config = result["resource"]["aws_ecr_repository_policy"]["test"]

      expect(config["repository"]).to eq("${aws_ecr_repository.main.name}")
    end

    it "supports terraform references for policy" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_ecr_repository_policy(:test, {
          repository: "my-repo",
          policy: "${data.aws_iam_policy_document.ecr_policy.json}"
        })
      end

      result = synthesizer.synthesis
      config = result["resource"]["aws_ecr_repository_policy"]["test"]

      expect(config["policy"]).to eq("${data.aws_iam_policy_document.ecr_policy.json}")
    end
  end

  describe "terraform validation" do
    it "produces valid terraform structure" do
      policy = valid_policy
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_ecr_repository_policy(:test, {
          repository: "my-repo",
          policy: policy
        })
      end

      result = synthesizer.synthesis

      expect(result).to be_a(Hash)
      expect(result["resource"]).to be_a(Hash)
      expect(result["resource"]["aws_ecr_repository_policy"]).to be_a(Hash)
      expect(result["resource"]["aws_ecr_repository_policy"]["test"]).to be_a(Hash)
    end

    it "rejects invalid JSON policy" do
      expect {
        synthesizer.instance_eval do
          extend Pangea::Resources::AWS
          aws_ecr_repository_policy(:test, {
            repository: "my-repo",
            policy: "not valid json"
          })
        end
      }.to raise_error(Dry::Struct::Error, /valid JSON/)
    end

    it "rejects policy without Statement" do
      expect {
        synthesizer.instance_eval do
          extend Pangea::Resources::AWS
          aws_ecr_repository_policy(:test, {
            repository: "my-repo",
            policy: JSON.generate({ "Version" => "2012-10-17" })
          })
        end
      }.to raise_error(Dry::Struct::Error, /Statement/)
    end
  end

  describe "resource references" do
    it "returns a resource reference with outputs" do
      ref = nil
      policy = valid_policy
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        ref = aws_ecr_repository_policy(:test, {
          repository: "my-repo",
          policy: policy
        })
      end

      expect(ref).to be_a(Pangea::Resources::ResourceReference)
      expect(ref.outputs[:repository]).to eq("${aws_ecr_repository_policy.test.repository}")
      expect(ref.outputs[:registry_id]).to eq("${aws_ecr_repository_policy.test.registry_id}")
    end

    it "provides computed properties for pull access" do
      ref = nil
      policy = valid_policy
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        ref = aws_ecr_repository_policy(:test, {
          repository: "my-repo",
          policy: policy
        })
      end

      expect(ref.statement_count).to eq(1)
      expect(ref.grants_pull_access).to eq(true)
      expect(ref.grants_push_access).to eq(false)
      expect(ref.is_terraform_reference).to eq(false)
      expect(ref.allowed_actions).to include("ecr:GetDownloadUrlForLayer")
    end

    it "provides computed properties for push access" do
      ref = nil
      push_policy = JSON.generate({
        "Version" => "2012-10-17",
        "Statement" => [
          {
            "Effect" => "Allow",
            "Principal" => {
              "AWS" => "arn:aws:iam::123456789012:root"
            },
            "Action" => [
              "ecr:PutImage",
              "ecr:InitiateLayerUpload",
              "ecr:UploadLayerPart",
              "ecr:CompleteLayerUpload"
            ]
          }
        ]
      })

      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        ref = aws_ecr_repository_policy(:test, {
          repository: "my-repo",
          policy: push_policy
        })
      end

      expect(ref.grants_push_access).to eq(true)
    end
  end
end
