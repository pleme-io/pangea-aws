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
      module CloudFrontDistribution
        # Builds distribution settings blocks for CloudFront distributions
        module SettingsBuilder
          module_function

          def build_basic_settings(context, attrs)
            context.comment attrs.comment
            context.default_root_object attrs.default_root_object if attrs.default_root_object
            context.enabled attrs.enabled
            context.http_version attrs.http_version
            context.is_ipv6_enabled attrs.is_ipv6_enabled
            context.price_class attrs.price_class
            context.aliases attrs.aliases if attrs.aliases.any?
            context.web_acl_id attrs.web_acl_id if attrs.web_acl_id
            context.retain_on_delete attrs.retain_on_delete
            context.wait_for_deployment attrs.wait_for_deployment
          end

          def build_custom_error_responses(context, error_responses)
            error_responses.each do |error_response|
              context.custom_error_response do
                context.error_code error_response[:error_code]
                context.response_code error_response[:response_code] if error_response[:response_code]
                context.response_page_path error_response[:response_page_path] if error_response[:response_page_path]
                context.error_caching_min_ttl error_response[:error_caching_min_ttl] if error_response[:error_caching_min_ttl]
              end
            end
          end

          def build_restrictions(context, restrictions)
            return unless restrictions

            geo = restrictions[:geo_restriction]
            return unless geo

            context.restrictions do
              context.geo_restriction do
                context.restriction_type geo[:restriction_type]
                context.locations geo[:locations] if geo[:locations]&.any?
              end
            end
          end

          def build_viewer_certificate(context, cert)
            context.viewer_certificate do
              context.acm_certificate_arn cert[:acm_certificate_arn] if cert[:acm_certificate_arn]
              context.iam_certificate_id cert[:iam_certificate_id] if cert[:iam_certificate_id]
              context.cloudfront_default_certificate cert[:cloudfront_default_certificate] if cert.key?(:cloudfront_default_certificate)
              context.ssl_support_method cert[:ssl_support_method] if cert[:ssl_support_method]
              context.minimum_protocol_version cert[:minimum_protocol_version] if cert[:minimum_protocol_version]
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
