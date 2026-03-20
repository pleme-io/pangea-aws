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
require 'pangea/resources/aws_ecr_lifecycle_policy/resource'
require 'json'

RSpec.describe "aws_ecr_lifecycle_policy synthesis" do
  include Pangea::Resources::AWS

  let(:synthesizer) { TerraformSynthesizer.new }

  let(:valid_policy) do
    JSON.generate({
      "rules" => [
        {
          "rulePriority" => 1,
          "description" => "Keep last 10 images",
          "selection" => {
            "tagStatus" => "any",
            "countType" => "imageCountMoreThan",
            "countNumber" => 10
          },
          "action" => {
            "type" => "expire"
          }
        }
      ]
    })
  end

  describe "terraform generation" do
    it "generates valid terraform JSON" do
      policy = valid_policy
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_ecr_lifecycle_policy(:test, {
          repository: "my-repo",
          policy: policy
        })
      end

      result = synthesizer.synthesis

      expect(result).to have_key("resource")
      expect(result["resource"]).to have_key("aws_ecr_lifecycle_policy")
      expect(result["resource"]["aws_ecr_lifecycle_policy"]).to have_key("test")

      config = result["resource"]["aws_ecr_lifecycle_policy"]["test"]
      expect(config["repository"]).to eq("my-repo")
      expect(config["policy"]).to eq(policy)
    end

    it "supports age-based cleanup rules" do
      age_policy = JSON.generate({
        "rules" => [
          {
            "rulePriority" => 1,
            "description" => "Delete images older than 30 days",
            "selection" => {
              "tagStatus" => "untagged",
              "countType" => "sinceImagePushed",
              "countUnit" => "days",
              "countNumber" => 30
            },
            "action" => {
              "type" => "expire"
            }
          }
        ]
      })

      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_ecr_lifecycle_policy(:test, {
          repository: "my-repo",
          policy: age_policy
        })
      end

      result = synthesizer.synthesis
      config = result["resource"]["aws_ecr_lifecycle_policy"]["test"]

      expect(config["policy"]).to eq(age_policy)
    end

    it "supports terraform references for repository" do
      policy = valid_policy
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_ecr_lifecycle_policy(:test, {
          repository: "${aws_ecr_repository.main.name}",
          policy: policy
        })
      end

      result = synthesizer.synthesis
      config = result["resource"]["aws_ecr_lifecycle_policy"]["test"]

      expect(config["repository"]).to eq("${aws_ecr_repository.main.name}")
    end
  end

  describe "terraform validation" do
    it "produces valid terraform structure" do
      policy = valid_policy
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_ecr_lifecycle_policy(:test, {
          repository: "my-repo",
          policy: policy
        })
      end

      result = synthesizer.synthesis

      expect(result).to be_a(Hash)
      expect(result["resource"]).to be_a(Hash)
      expect(result["resource"]["aws_ecr_lifecycle_policy"]).to be_a(Hash)
      expect(result["resource"]["aws_ecr_lifecycle_policy"]["test"]).to be_a(Hash)
    end

    it "rejects invalid JSON policy" do
      expect {
        synthesizer.instance_eval do
          extend Pangea::Resources::AWS
          aws_ecr_lifecycle_policy(:test, {
            repository: "my-repo",
            policy: "not valid json"
          })
        end
      }.to raise_error(Dry::Struct::Error, /valid JSON/)
    end

    it "rejects policy without rules" do
      expect {
        synthesizer.instance_eval do
          extend Pangea::Resources::AWS
          aws_ecr_lifecycle_policy(:test, {
            repository: "my-repo",
            policy: JSON.generate({ "other" => "data" })
          })
        end
      }.to raise_error(Dry::Struct::Error, /rules/)
    end
  end

  describe "resource references" do
    it "returns a resource reference with outputs" do
      ref = nil
      policy = valid_policy
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        ref = aws_ecr_lifecycle_policy(:test, {
          repository: "my-repo",
          policy: policy
        })
      end

      expect(ref).to be_a(Pangea::Resources::ResourceReference)
      expect(ref.outputs[:repository]).to eq("${aws_ecr_lifecycle_policy.test.repository}")
      expect(ref.outputs[:registry_id]).to eq("${aws_ecr_lifecycle_policy.test.registry_id}")
    end

    it "provides computed properties" do
      ref = nil
      policy = JSON.generate({
        "rules" => [
          {
            "rulePriority" => 1,
            "description" => "Keep last 5 tagged images",
            "selection" => {
              "tagStatus" => "tagged",
              "tagPrefixList" => ["prod"],
              "countType" => "imageCountMoreThan",
              "countNumber" => 5
            },
            "action" => { "type" => "expire" }
          },
          {
            "rulePriority" => 2,
            "description" => "Delete untagged images older than 7 days",
            "selection" => {
              "tagStatus" => "untagged",
              "countType" => "sinceImagePushed",
              "countUnit" => "days",
              "countNumber" => 7
            },
            "action" => { "type" => "expire" }
          }
        ]
      })

      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        ref = aws_ecr_lifecycle_policy(:test, {
          repository: "my-repo",
          policy: policy
        })
      end

      expect(ref.rule_count).to eq(2)
      expect(ref.rule_priorities).to eq([1, 2])
      expect(ref.has_tagged_image_rules).to eq(true)
      expect(ref.has_untagged_image_rules).to eq(true)
      expect(ref.has_count_based_rules).to eq(true)
      expect(ref.has_age_based_rules).to eq(true)
      expect(ref.is_terraform_reference).to eq(false)
    end
  end
end
