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

require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
        # Type-safe attributes for AWS ACM PCA Certificate Authority resources
        class AcmPcaCertificateAuthorityAttributes < Dry::Struct
          # Certificate authority configuration
          attribute :certificate_authority_configuration, Resources::Types::Hash.schema(
            key_algorithm: Resources::Types::String.constrained(included_in: ['RSA_2048', 'RSA_4096', 'EC_prime256v1', 'EC_secp384r1']),
            signing_algorithm: Resources::Types::String.constrained(included_in: ['SHA256WITHRSA', 'SHA384WITHRSA', 'SHA512WITHRSA',
              'SHA256WITHECDSA', 'SHA384WITHECDSA', 'SHA512WITHECDSA']),
            subject: Resources::Types::Hash.schema(
              country?: Resources::Types::String.optional,
              organization?: Resources::Types::String.optional,
              organizational_unit?: Resources::Types::String.optional,
              distinguished_name_qualifier?: Resources::Types::String.optional,
              state?: Resources::Types::String.optional,
              common_name?: Resources::Types::String.optional,
              serial_number?: Resources::Types::String.optional,
              locality?: Resources::Types::String.optional,
              title?: Resources::Types::String.optional,
              surname?: Resources::Types::String.optional,
              given_name?: Resources::Types::String.optional,
              initials?: Resources::Types::String.optional,
              pseudonym?: Resources::Types::String.optional,
              generation_qualifier?: Resources::Types::String.optional
            )
          )

          # Certificate authority type
          attribute :type, Resources::Types::String.default('ROOT').enum('ROOT', 'SUBORDINATE')

          # Certificate authority status
          attribute :status, Resources::Types::String.constrained(included_in: ['CREATING', 'PENDING_CERTIFICATE', 'ACTIVE', 'DELETED', 'DISABLED', 'EXPIRED', 'FAILED']).optional

          # Permanent deletion time in days (7-30)
          attribute :permanent_deletion_time_in_days,
                    Resources::Types::Integer.constrained(gteq: 7, lteq: 30).default(30)

          # Revocation configuration
          attribute :revocation_configuration, Resources::Types::Hash.schema(
            crl_configuration?: Resources::Types::Hash.schema(
              enabled: Resources::Types::Bool,
              expiration_in_days?: Resources::Types::Integer.optional,
              custom_cname?: Resources::Types::String.optional,
              s3_bucket_name?: Resources::Types::String.optional,
              s3_object_acl?: Resources::Types::String.constrained(included_in: ['PUBLIC_READ', 'BUCKET_OWNER_FULL_CONTROL']).optional
            ).optional,
            ocsp_configuration?: Resources::Types::Hash.schema(
              enabled: Resources::Types::Bool,
              ocsp_custom_cname?: Resources::Types::String.optional
            ).optional
          ).optional

          # Usage mode
          attribute :usage_mode,
                    Resources::Types::String.constrained(included_in: ['GENERAL_PURPOSE', 'SHORT_LIVED_CERTIFICATE']).optional

          # Key storage security standard
          attribute :key_storage_security_standard,
                    Resources::Types::String.constrained(included_in: ['FIPS_140_2_LEVEL_2_OR_HIGHER', 'FIPS_140_2_LEVEL_3_OR_HIGHER']).optional

          # Tags to apply to the certificate authority
          attribute :tags, Resources::Types::AwsTags.default({}.freeze)
        end
      end
    end
  end
end
