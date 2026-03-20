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
require 'pangea/resources/aws_s3_bucket_lifecycle_configuration/resource'

RSpec.describe 'aws_s3_bucket_lifecycle_configuration synthesis' do
  # NOTE: LifecycleRule resolves to Dry::Types::Lax after full pangea-aws load
  # due to const_defined? guard. Testing S3BucketLifecycleConfigurationAttributes
  # class which IS available as a proper Class.
  let(:attrs_class) { Pangea::Resources::AWS::Types::S3BucketLifecycleConfigurationAttributes }

  describe 'module structure' do
    it 'defines the resource method on AWS module' do
      expect(Pangea::Resources::AWS.method_defined?(:aws_s3_bucket_lifecycle_configuration)).to be true
    end

    it 'defines S3BucketLifecycleConfigurationAttributes as a class' do
      expect(attrs_class).to be_a(Class)
      expect(attrs_class.ancestors).to include(Pangea::Resources::BaseAttributes)
    end

    it 'defines LifecycleRule constant in Types module' do
      expect(Pangea::Resources::AWS::Types.const_defined?(:LifecycleRule)).to be true
    end
  end

  describe 'attribute definitions' do
    it 'defines bucket attribute' do
      schema = attrs_class.schema
      expect(schema.keys.map(&:name)).to include(:bucket)
    end

    it 'defines rule attribute' do
      schema = attrs_class.schema
      expect(schema.keys.map(&:name)).to include(:rule)
    end

    it 'defines expected_bucket_owner attribute' do
      schema = attrs_class.schema
      expect(schema.keys.map(&:name)).to include(:expected_bucket_owner)
    end
  end
end
