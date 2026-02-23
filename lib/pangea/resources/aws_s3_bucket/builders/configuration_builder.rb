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

module Pangea
  module Resources
    module AWS
      module S3Bucket
        # Builds core configuration blocks for S3 buckets
        module ConfigurationBuilder
          module_function

          def build_versioning(context, versioning)
            return unless versioning[:enabled] || versioning[:mfa_delete]

            context.versioning do
              context.enabled versioning[:enabled]
              context.mfa_delete versioning[:mfa_delete] if versioning[:mfa_delete]
            end
          end

          def build_encryption(context, encryption_config)
            return unless encryption_config[:rule]

            context.server_side_encryption_configuration do
              context.rule do
                context.apply_server_side_encryption_by_default do
                  context.sse_algorithm encryption_config[:rule][:apply_server_side_encryption_by_default][:sse_algorithm]
                  kms_key = encryption_config[:rule][:apply_server_side_encryption_by_default][:kms_master_key_id]
                  context.kms_master_key_id kms_key if kms_key
                end
                context.bucket_key_enabled encryption_config[:rule][:bucket_key_enabled] if encryption_config[:rule][:bucket_key_enabled]
              end
            end
          end

          def build_logging(context, logging)
            return unless logging&.dig(:target_bucket)

            context.logging do
              context.target_bucket logging[:target_bucket]
              context.target_prefix logging[:target_prefix] if logging[:target_prefix]
            end
          end

          def build_object_lock(context, object_lock_config)
            return unless object_lock_config&.dig(:object_lock_enabled)

            context.object_lock_configuration do
              context.object_lock_enabled object_lock_config[:object_lock_enabled]
              build_object_lock_rule(context, object_lock_config[:rule]) if object_lock_config[:rule]
            end
          end

          def build_object_lock_rule(context, rule_config)
            context.rule do
              context.default_retention do
                context.mode rule_config[:default_retention][:mode]
                context.days rule_config[:default_retention][:days] if rule_config[:default_retention][:days]
                context.years rule_config[:default_retention][:years] if rule_config[:default_retention][:years]
              end
            end
          end

          def build_website(context, website)
            return unless website&.any?

            context.website do
              if website[:redirect_all_requests_to]
                context.redirect_all_requests_to do
                  context.host_name website[:redirect_all_requests_to][:host_name]
                  context.protocol website[:redirect_all_requests_to][:protocol] if website[:redirect_all_requests_to][:protocol]
                end
              else
                context.index_document website[:index_document] if website[:index_document]
                context.error_document website[:error_document] if website[:error_document]
                context.routing_rules website[:routing_rules] if website[:routing_rules]
              end
            end
          end

          def build_tags(context, tags)
            return unless tags&.any?

            context.tags do
              tags.each { |key, value| context.public_send(key, value) }
            end
          end
        end
      end
    end
  end
end
