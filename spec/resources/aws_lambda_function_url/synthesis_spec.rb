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
require 'pangea/resources/aws_lambda_function_url/resource'

RSpec.describe "aws_lambda_function_url synthesis" do
  include Pangea::Resources::AWS

  let(:synthesizer) { TerraformSynthesizer.new }

  describe "terraform generation" do
    it "generates valid terraform JSON with required attributes" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_lambda_function_url(:test, {
          authorization_type: "NONE",
          function_name: "my-function"
        })
      end

      result = synthesizer.synthesis

      expect(result).to have_key("resource")
      expect(result["resource"]).to have_key("aws_lambda_function_url")
      expect(result["resource"]["aws_lambda_function_url"]).to have_key("test")

      config = result["resource"]["aws_lambda_function_url"]["test"]
      expect(config["authorization_type"]).to eq("NONE")
      expect(config["function_name"]).to eq("my-function")
    end

    it "supports CORS configuration" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_lambda_function_url(:test, {
          authorization_type: "NONE",
          function_name: "my-function",
          cors: {
            allow_credentials: true,
            allow_headers: ["content-type", "authorization"],
            allow_methods: ["GET", "POST"],
            allow_origins: ["https://example.com"],
            expose_headers: ["x-custom-header"],
            max_age: 3600
          }
        })
      end

      result = synthesizer.synthesis
      config = result["resource"]["aws_lambda_function_url"]["test"]

      expect(config).to have_key("cors")
    end

    it "supports invoke mode for streaming" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_lambda_function_url(:test, {
          authorization_type: "AWS_IAM",
          function_name: "my-function",
          invoke_mode: "RESPONSE_STREAM"
        })
      end

      result = synthesizer.synthesis
      config = result["resource"]["aws_lambda_function_url"]["test"]

      expect(config["invoke_mode"]).to eq("RESPONSE_STREAM")
    end

    it "supports qualifier" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_lambda_function_url(:test, {
          authorization_type: "NONE",
          function_name: "my-function",
          qualifier: "prod"
        })
      end

      result = synthesizer.synthesis
      config = result["resource"]["aws_lambda_function_url"]["test"]

      expect(config["qualifier"]).to eq("prod")
    end
  end

  describe "terraform validation" do
    it "produces valid terraform structure" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_lambda_function_url(:test, {
          authorization_type: "NONE",
          function_name: "my-function"
        })
      end

      result = synthesizer.synthesis

      expect(result).to be_a(Hash)
      expect(result["resource"]).to be_a(Hash)
      expect(result["resource"]["aws_lambda_function_url"]).to be_a(Hash)
      expect(result["resource"]["aws_lambda_function_url"]["test"]).to be_a(Hash)
    end

    it "rejects invalid authorization type" do
      expect {
        synthesizer.instance_eval do
          extend Pangea::Resources::AWS
          aws_lambda_function_url(:test, {
            authorization_type: "INVALID",
            function_name: "my-function"
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
        ref = aws_lambda_function_url(:test, {
          authorization_type: "NONE",
          function_name: "my-function"
        })
      end

      expect(ref).to be_a(Pangea::Resources::ResourceReference)
      expect(ref.id).to eq("${aws_lambda_function_url.test.id}")
      expect(ref.outputs[:function_url]).to eq("${aws_lambda_function_url.test.function_url}")
      expect(ref.outputs[:url_id]).to eq("${aws_lambda_function_url.test.url_id}")
    end

    it "provides computed properties for public access" do
      ref = nil
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        ref = aws_lambda_function_url(:test, {
          authorization_type: "NONE",
          function_name: "my-function"
        })
      end

      expect(ref.public_access).to eq(true)
      expect(ref.iam_protected).to eq(false)
      expect(ref.has_cors_configuration).to eq(false)
      expect(ref.streaming_enabled).to eq(false)
    end

    it "provides computed properties for IAM-protected URL with CORS" do
      ref = nil
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        ref = aws_lambda_function_url(:test, {
          authorization_type: "AWS_IAM",
          function_name: "my-function",
          cors: {
            allow_methods: ["GET", "POST"],
            allow_origins: ["https://example.com"]
          },
          invoke_mode: "RESPONSE_STREAM",
          qualifier: "prod"
        })
      end

      expect(ref.public_access).to eq(false)
      expect(ref.iam_protected).to eq(true)
      expect(ref.has_cors_configuration).to eq(true)
      expect(ref.streaming_enabled).to eq(true)
      expect(ref.has_qualifier).to eq(true)
      expect(ref.cors_methods).to eq(["GET", "POST"])
      expect(ref.cors_origins).to eq(["https://example.com"])
    end
  end
end
