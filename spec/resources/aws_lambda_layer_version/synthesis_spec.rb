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
require 'pangea/resources/aws_lambda_layer_version/resource'

RSpec.describe "aws_lambda_layer_version synthesis" do
  include Pangea::Resources::AWS

  let(:synthesizer) { TerraformSynthesizer.new }

  describe "terraform generation" do
    it "generates valid terraform JSON with filename source" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_lambda_layer_version(:test, {
          layer_name: "my-layer",
          filename: "layer.zip",
          compatible_runtimes: ["python3.11", "python3.12"]
        })
      end

      result = synthesizer.synthesis

      expect(result).to have_key("resource")
      expect(result["resource"]).to have_key("aws_lambda_layer_version")
      expect(result["resource"]["aws_lambda_layer_version"]).to have_key("test")

      config = result["resource"]["aws_lambda_layer_version"]["test"]
      expect(config["layer_name"]).to eq("my-layer")
      expect(config["filename"]).to eq("layer.zip")
      expect(config["compatible_runtimes"]).to eq(["python3.11", "python3.12"])
    end

    it "generates valid terraform JSON with S3 source" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_lambda_layer_version(:test, {
          layer_name: "my-layer",
          s3_bucket: "my-bucket",
          s3_key: "layers/my-layer.zip"
        })
      end

      result = synthesizer.synthesis
      config = result["resource"]["aws_lambda_layer_version"]["test"]

      expect(config["s3_bucket"]).to eq("my-bucket")
      expect(config["s3_key"]).to eq("layers/my-layer.zip")
    end

    it "supports compatible architectures" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_lambda_layer_version(:test, {
          layer_name: "my-layer",
          filename: "layer.zip",
          compatible_architectures: ["x86_64", "arm64"],
          compatible_runtimes: ["python3.11"]
        })
      end

      result = synthesizer.synthesis
      config = result["resource"]["aws_lambda_layer_version"]["test"]

      expect(config["compatible_architectures"]).to eq(["x86_64", "arm64"])
    end

    it "supports description and license info" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_lambda_layer_version(:test, {
          layer_name: "my-layer",
          filename: "layer.zip",
          description: "Shared utilities layer",
          license_info: "MIT"
        })
      end

      result = synthesizer.synthesis
      config = result["resource"]["aws_lambda_layer_version"]["test"]

      expect(config["description"]).to eq("Shared utilities layer")
      expect(config["license_info"]).to eq("MIT")
    end
  end

  describe "terraform validation" do
    it "produces valid terraform structure" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_lambda_layer_version(:test, {
          layer_name: "my-layer",
          filename: "layer.zip"
        })
      end

      result = synthesizer.synthesis

      expect(result).to be_a(Hash)
      expect(result["resource"]).to be_a(Hash)
      expect(result["resource"]["aws_lambda_layer_version"]).to be_a(Hash)
      expect(result["resource"]["aws_lambda_layer_version"]["test"]).to be_a(Hash)
    end

    it "rejects missing code source" do
      expect {
        synthesizer.instance_eval do
          extend Pangea::Resources::AWS
          aws_lambda_layer_version(:test, {
            layer_name: "my-layer"
          })
        end
      }.to raise_error(Dry::Struct::Error, /filename or s3_bucket/)
    end

    it "rejects both filename and s3_bucket" do
      expect {
        synthesizer.instance_eval do
          extend Pangea::Resources::AWS
          aws_lambda_layer_version(:test, {
            layer_name: "my-layer",
            filename: "layer.zip",
            s3_bucket: "my-bucket",
            s3_key: "layers/layer.zip"
          })
        end
      }.to raise_error(Dry::Struct::Error, /Cannot specify both/)
    end
  end

  describe "resource references" do
    it "returns a resource reference with outputs" do
      ref = nil
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        ref = aws_lambda_layer_version(:test, {
          layer_name: "my-layer",
          filename: "layer.zip"
        })
      end

      expect(ref).to be_a(Pangea::Resources::ResourceReference)
      expect(ref.id).to eq("${aws_lambda_layer_version.test.id}")
      expect(ref.arn).to eq("${aws_lambda_layer_version.test.arn}")
      expect(ref.outputs[:layer_arn]).to eq("${aws_lambda_layer_version.test.layer_arn}")
      expect(ref.outputs[:version]).to eq("${aws_lambda_layer_version.test.version}")
    end

    it "provides computed properties" do
      ref = nil
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        ref = aws_lambda_layer_version(:test, {
          layer_name: "my-layer",
          filename: "layer.zip",
          compatible_runtimes: ["python3.11", "python3.12"],
          compatible_architectures: ["x86_64"]
        })
      end

      expect(ref.outputs[:is_runtime_specific]).to eq(true)
      expect(ref.outputs[:is_architecture_specific]).to eq(true)
      expect(ref.outputs[:supports_all_architectures]).to eq(false)
      expect(ref.outputs[:runtime_families]).to eq(["python"])
      expect(ref.outputs[:layer_type]).to eq("runtime-dependencies")
    end
  end
end
