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
require 'pangea/resources/aws_lambda_event_source_mapping/resource'

RSpec.describe "aws_lambda_event_source_mapping synthesis" do
  include Pangea::Resources::AWS

  let(:synthesizer) { TerraformSynthesizer.new }

  describe "terraform generation" do
    it "generates valid terraform JSON for SQS source" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_lambda_event_source_mapping(:test, {
          event_source_arn: "arn:aws:sqs:us-east-1:123456789012:my-queue",
          function_name: "my-function"
        })
      end

      result = synthesizer.synthesis

      expect(result).to have_key("resource")
      expect(result["resource"]).to have_key("aws_lambda_event_source_mapping")
      expect(result["resource"]["aws_lambda_event_source_mapping"]).to have_key("test")

      config = result["resource"]["aws_lambda_event_source_mapping"]["test"]
      expect(config["event_source_arn"]).to eq("arn:aws:sqs:us-east-1:123456789012:my-queue")
      expect(config["function_name"]).to eq("my-function")
      expect(config["enabled"]).to eq(true)
    end

    it "generates valid terraform JSON for Kinesis stream source" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_lambda_event_source_mapping(:test, {
          event_source_arn: "arn:aws:kinesis:us-east-1:123456789012:stream/my-stream",
          function_name: "my-function",
          starting_position: "LATEST",
          batch_size: 100
        })
      end

      result = synthesizer.synthesis
      config = result["resource"]["aws_lambda_event_source_mapping"]["test"]

      expect(config["starting_position"]).to eq("LATEST")
      expect(config["batch_size"]).to eq(100)
    end

    it "supports destination config for failure handling" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_lambda_event_source_mapping(:test, {
          event_source_arn: "arn:aws:sqs:us-east-1:123456789012:my-queue",
          function_name: "my-function",
          destination_config: {
            on_failure: {
              destination: "arn:aws:sqs:us-east-1:123456789012:dlq"
            }
          }
        })
      end

      result = synthesizer.synthesis
      config = result["resource"]["aws_lambda_event_source_mapping"]["test"]

      expect(config).to have_key("destination_config")
    end

    it "supports filter criteria" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_lambda_event_source_mapping(:test, {
          event_source_arn: "arn:aws:sqs:us-east-1:123456789012:my-queue",
          function_name: "my-function",
          filter_criteria: {
            filters: [
              { pattern: '{"body":{"type":["order"]}}' }
            ]
          }
        })
      end

      result = synthesizer.synthesis
      config = result["resource"]["aws_lambda_event_source_mapping"]["test"]

      expect(config).to have_key("filter_criteria")
    end
  end

  describe "terraform validation" do
    it "produces valid terraform structure" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_lambda_event_source_mapping(:test, {
          event_source_arn: "arn:aws:sqs:us-east-1:123456789012:my-queue",
          function_name: "my-function"
        })
      end

      result = synthesizer.synthesis

      expect(result).to be_a(Hash)
      expect(result["resource"]).to be_a(Hash)
      expect(result["resource"]["aws_lambda_event_source_mapping"]).to be_a(Hash)
      expect(result["resource"]["aws_lambda_event_source_mapping"]["test"]).to be_a(Hash)
    end
  end

  describe "resource references" do
    it "returns a resource reference with outputs" do
      ref = nil
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        ref = aws_lambda_event_source_mapping(:test, {
          event_source_arn: "arn:aws:sqs:us-east-1:123456789012:my-queue",
          function_name: "my-function"
        })
      end

      expect(ref).to be_a(Pangea::Resources::ResourceReference)
      expect(ref.id).to eq("${aws_lambda_event_source_mapping.test.id}")
      expect(ref.outputs[:uuid]).to eq("${aws_lambda_event_source_mapping.test.uuid}")
      expect(ref.outputs[:function_arn]).to eq("${aws_lambda_event_source_mapping.test.function_arn}")
      expect(ref.outputs[:state]).to eq("${aws_lambda_event_source_mapping.test.state}")
    end

    it "provides computed properties for SQS source" do
      ref = nil
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        ref = aws_lambda_event_source_mapping(:test, {
          event_source_arn: "arn:aws:sqs:us-east-1:123456789012:my-queue",
          function_name: "my-function"
        })
      end

      expect(ref.outputs[:source_type]).to eq("sqs")
      expect(ref.outputs[:is_stream_source]).to eq(false)
      expect(ref.outputs[:is_queue_source]).to eq(true)
      expect(ref.outputs[:is_kafka_source]).to eq(false)
    end

    it "provides computed properties for Kinesis source" do
      ref = nil
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        ref = aws_lambda_event_source_mapping(:test, {
          event_source_arn: "arn:aws:kinesis:us-east-1:123456789012:stream/my-stream",
          function_name: "my-function",
          starting_position: "LATEST"
        })
      end

      expect(ref.outputs[:source_type]).to eq("kinesis")
      expect(ref.outputs[:is_stream_source]).to eq(true)
      expect(ref.outputs[:supports_parallelization]).to eq(true)
    end
  end
end
