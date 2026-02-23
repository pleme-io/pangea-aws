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

require 'securerandom'

module Pangea
  module Resources
    module AWS
      module Types
        class IamUserAttributes < Pangea::Resources::BaseAttributes
          ADMIN_PATTERNS = /admin|super|root/i.freeze
          SERVICE_PATTERNS = /(-service$|-svc$|\.svc$|^service-|^app-|^system-)/i.freeze
          HUMAN_PATTERN = /\A[a-z]+\.[a-z]+\z/i.freeze

          def administrative_user?
            !!(name&.match?(ADMIN_PATTERNS))
          end

          def service_user?
            !!(name&.match?(SERVICE_PATTERNS))
          end

          def human_user?
            !!(name&.match?(HUMAN_PATTERN))
          end

          def user_category
            return :administrative if administrative_user?
            return :service_account if service_user?
            return :human_user if human_user?

            :generic
          end

          def organizational_path?
            path != '/'
          end

          def organizational_unit
            return nil unless organizational_path?

            path.split('/').reject(&:empty?).first
          end

          def has_permissions_boundary?
            !permissions_boundary.nil?
          end

          def permissions_boundary_policy_name
            return nil unless has_permissions_boundary?

            permissions_boundary.split('/').last
          end

          def security_risk_level
            if administrative_user? && !has_permissions_boundary?
              :high
            elsif !has_permissions_boundary?
              :medium
            else
              :low
            end
          end

          def user_arn(account_id = '123456789012')
            path_segment = path == '/' ? '' : path.delete_prefix('/').delete_suffix('/')
            if path_segment.empty?
              "arn:aws:iam::#{account_id}:user/#{name}"
            else
              "arn:aws:iam::#{account_id}:user/#{path_segment}/#{name}"
            end
          end

          def self.generate_secure_password(length = 16)
            chars = [('a'..'z'), ('A'..'Z'), ('0'..'9'), ['!', '@', '#', '$', '%', '^', '&', '*']].map(&:to_a).flatten
            Array.new(length) { chars[SecureRandom.random_number(chars.length)] }.join
          end
        end
      end
    end
  end
end
