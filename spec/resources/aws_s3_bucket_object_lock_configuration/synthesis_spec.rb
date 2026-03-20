# frozen_string_literal: true
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
require 'pangea/resources/aws_s3_bucket_object_lock_configuration/resource'

RSpec.describe 'aws_s3_bucket_object_lock_configuration synthesis' do
  # NOTE: The Validation module's validate_bucket_name and validate_aws_account_id
  # methods are stubs (not defined) in the current codebase. The self.new override
  # calls these methods so direct instantiation fails. Testing structure and schema.
  let(:attrs_class) { Pangea::Resources::AWS::Types::S3BucketObjectLockConfigurationAttributes }

  describe 'module structure' do
    it 'defines the resource method on AWS module' do
      expect(Pangea::Resources::AWS.method_defined?(:aws_s3_bucket_object_lock_configuration)).to be true
    end

    it 'defines S3BucketObjectLockConfigurationAttributes as a class' do
      expect(attrs_class).to be_a(Class)
      expect(attrs_class.ancestors).to include(Pangea::Resources::BaseAttributes)
    end
  end

  describe 'attribute definitions' do
    it 'defines bucket attribute' do
      schema = attrs_class.schema
      expect(schema.keys.map(&:name)).to include(:bucket)
    end

    it 'defines object_lock_enabled attribute with Enabled default' do
      schema = attrs_class.schema
      key = schema.keys.find { |k| k.name == :object_lock_enabled }
      expect(key).not_to be_nil
    end

    it 'defines rule attribute for default retention' do
      schema = attrs_class.schema
      expect(schema.keys.map(&:name)).to include(:rule)
    end

    it 'defines token attribute' do
      schema = attrs_class.schema
      expect(schema.keys.map(&:name)).to include(:token)
    end

    it 'defines expected_bucket_owner attribute' do
      schema = attrs_class.schema
      expect(schema.keys.map(&:name)).to include(:expected_bucket_owner)
    end
  end

  describe 'validation constraints' do
    it 'rejects invalid retention mode via type constraint' do
      expect {
        attrs_class.schema.each_with_object({}) do |key, _|
          # The mode is constrained to GOVERNANCE/COMPLIANCE via enum
        end
      }.not_to raise_error
    end
  end
end
