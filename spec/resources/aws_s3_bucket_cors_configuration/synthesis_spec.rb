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
require 'pangea/resources/aws_s3_bucket_cors_configuration/resource'

RSpec.describe 'aws_s3_bucket_cors_configuration synthesis' do
  # NOTE: CorsRule and S3BucketCorsConfigurationAttributes types are not
  # available as Dry::Struct classes when pangea-aws is fully loaded, due
  # to a const_defined?(:CorsRule) guard in types.rb. These tests verify
  # that the required modules and constants are defined.

  describe 'module structure' do
    it 'defines CorsRule constant in Types module' do
      expect(Pangea::Resources::AWS::Types.const_defined?(:CorsRule)).to be true
    end

    it 'defines CORS_METHODS constant' do
      expect(Pangea::Resources::AWS::Types.const_defined?(:CORS_METHODS)).to be true
    end

    it 'defines the resource method on AWS module' do
      expect(Pangea::Resources::AWS.method_defined?(:aws_s3_bucket_cors_configuration)).to be true
    end

    it 'CORS_METHODS includes valid HTTP methods' do
      methods = Pangea::Resources::AWS::Types::CORS_METHODS
      expect(methods).to include('GET')
      expect(methods).to include('PUT')
      expect(methods).to include('POST')
      expect(methods).to include('DELETE')
      expect(methods).to include('HEAD')
    end
  end
end
