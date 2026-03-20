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
require 'pangea/resources/aws_vpc_security_group_egress_rule/resource'

RSpec.describe "aws_vpc_security_group_egress_rule synthesis" do
  include Pangea::Resources::AWS

  let(:synthesizer) { TerraformSynthesizer.new }

  describe "terraform generation" do
    it "generates valid terraform JSON with tags" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_vpc_security_group_egress_rule(:test, {
          tags: { Name: "test-egress-rule" }
        })
      end

      result = synthesizer.synthesis

      expect(result).to have_key("resource")
      expect(result["resource"]).to have_key("aws_vpc_security_group_egress_rule")
      expect(result["resource"]["aws_vpc_security_group_egress_rule"]).to have_key("test")
    end

    it "includes tags when provided" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_vpc_security_group_egress_rule(:tagged, {
          tags: { Name: "test-egress-rule", Environment: "test" }
        })
      end

      result = synthesizer.synthesis
      config = result["resource"]["aws_vpc_security_group_egress_rule"]["tagged"]

      expect(config).to have_key("tags")
      expect(config["tags"]["Name"]).to eq("test-egress-rule")
      expect(config["tags"]["Environment"]).to eq("test")
    end
  end

  describe "resource reference" do
    it "returns a ResourceReference with correct outputs" do
      ref = nil
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        ref = aws_vpc_security_group_egress_rule(:test_ref, {})
      end

      expect(ref).to be_a(Pangea::Resources::ResourceReference)
      expect(ref.outputs[:id]).to eq("${aws_vpc_security_group_egress_rule.test_ref.id}")
    end
  end

  describe "terraform validation" do
    it "produces valid terraform structure" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_vpc_security_group_egress_rule(:test, {
          tags: { Name: "validation-test" }
        })
      end

      result = synthesizer.synthesis

      expect(result).to be_a(Hash)
      expect(result["resource"]).to be_a(Hash)
      expect(result["resource"]["aws_vpc_security_group_egress_rule"]).to be_a(Hash)
      expect(result["resource"]["aws_vpc_security_group_egress_rule"]["test"]).to be_a(Hash)
    end
  end
end
