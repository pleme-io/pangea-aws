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


require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/aws_ecr_repository/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS ECR Repository with type-safe attributes
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] ECR Repository attributes
      # @option attributes [String] :name The name of the repository
      # @option attributes [String] :image_tag_mutability Image tag mutability (MUTABLE or IMMUTABLE)
      # @option attributes [Hash] :image_scanning_configuration Image scanning configuration
      # @option attributes [Hash] :encryption_configuration Encryption configuration
      # @option attributes [Boolean] :force_delete Force delete the repository even if it contains images
      # @option attributes [Hash] :tags Tags to apply to the repository
      # @return [ResourceReference] Reference object with outputs and computed properties
      #
      # @example Basic ECR repository
      #   app_repo = aws_ecr_repository(:app, {
      #     name: "myapp",
      #     image_tag_mutability: "MUTABLE",
      #     image_scanning_configuration: {
      #       scan_on_push: true
      #     },
      #     tags: {
      #       Environment: "production",
      #       Application: "web"
      #     }
      #   })
      #
      # @example Immutable repository with KMS encryption
      #   secure_repo = aws_ecr_repository(:secure, {
      #     name: "secure-app",
      #     image_tag_mutability: "IMMUTABLE",
      #     encryption_configuration: {
      #       encryption_type: "KMS",
      #       kms_key: kms_key.arn
      #     },
      #     image_scanning_configuration: {
      #       scan_on_push: true
      #     },
      #     tags: {
      #       Security: "high",
      #       Environment: "production"
      #     }
      #   })
      #
      # @example Development repository with force delete
      #   dev_repo = aws_ecr_repository(:dev, {
      #     name: "myapp-dev",
      #     force_delete: true,
      #     tags: {
      #       Environment: "development"
      #     }
      #   })
      def aws_ecr_repository(name, attributes = {})
        # Validate attributes using dry-struct
        repo_attrs = Types::ECRRepositoryAttributes.new(attributes)

        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_ecr_repository, name) do
          # Repository name
          name repo_attrs.name

          # Image tag mutability
          image_tag_mutability repo_attrs.image_tag_mutability

          # Image scanning configuration (pass as hash, not block)
          image_scanning_configuration({ scan_on_push: repo_attrs.scan_on_push_enabled? })

          # Encryption configuration if specified (wrap in array for Terraform)
          if repo_attrs.encryption_configuration
            enc = repo_attrs.encryption_configuration
            enc_hash = { encryption_type: enc[:encryption_type] }
            enc_hash[:kms_key] = enc[:kms_key] if enc[:kms_key]
            encryption_configuration [enc_hash]
          end

          # Force delete
          force_delete repo_attrs.force_delete

          # Apply tags if present (pass as hash, not block)
          tags repo_attrs.tags if repo_attrs.tags&.any?
        end
        
        # Return resource reference with available outputs
        ref = ResourceReference.new(
          type: 'aws_ecr_repository',
          name: name,
          resource_attributes: repo_attrs.to_h,
          outputs: {
            arn: "${aws_ecr_repository.#{name}.arn}",
            name: "${aws_ecr_repository.#{name}.name}",
            registry_id: "${aws_ecr_repository.#{name}.registry_id}",
            repository_url: "${aws_ecr_repository.#{name}.repository_url}",
            tags_all: "${aws_ecr_repository.#{name}.tags_all}"
          }
        )
        
        # Add computed properties via method delegation
        ref.define_singleton_method(:repository_uri_template) { repo_attrs.repository_uri_template }
        ref.define_singleton_method(:registry_id_template) { repo_attrs.registry_id_template }
        ref.define_singleton_method(:is_immutable?) { repo_attrs.is_immutable? }
        ref.define_singleton_method(:scan_on_push_enabled?) { repo_attrs.scan_on_push_enabled? }
        ref.define_singleton_method(:uses_kms_encryption?) { repo_attrs.uses_kms_encryption? }
        ref.define_singleton_method(:uses_aes256_encryption?) { repo_attrs.uses_aes256_encryption? }
        ref.define_singleton_method(:allows_force_delete?) { repo_attrs.allows_force_delete? }
        
        ref
      end
    end
  end
end
