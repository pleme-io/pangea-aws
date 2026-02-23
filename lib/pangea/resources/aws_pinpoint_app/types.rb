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

require "dry-struct"
require 'pangea/resources/types'

module Pangea
  module Resources
    module AwsPinpointApp
      module Types
        # Campaign hook for Lambda integration
        class CampaignHook < Pangea::Resources::BaseAttributes
          attribute :lambda_function_name?, Pangea::Resources::Types::String
          attribute :mode?, Pangea::Resources::Types::String.constrained(included_in: ["DELIVERY", "FILTER"])
          attribute :web_url?, Pangea::Resources::Types::String
        end

        # Quiet time configuration
        class QuietTime < Pangea::Resources::BaseAttributes
          attribute :end?, Pangea::Resources::Types::String  # HH:MM format
          attribute :start?, Pangea::Resources::Types::String  # HH:MM format
        end

        # Application limits
        class Limits < Pangea::Resources::BaseAttributes
          attribute :daily?, Pangea::Resources::Types::Integer
          attribute :maximum_duration?, Pangea::Resources::Types::Integer
          attribute :messages_per_second?, Pangea::Resources::Types::Integer
          attribute :total?, Pangea::Resources::Types::Integer
        end

        # Main attributes for Pinpoint app
        unless const_defined?(:Attributes)
        class Attributes < Pangea::Resources::BaseAttributes
          # Required attributes
          attribute? :name, Pangea::Resources::Types::String.optional
          
          # Optional attributes
          attribute :name_prefix?, Pangea::Resources::Types::String
          attribute :campaign_hook?, CampaignHook
          attribute :limits?, Limits
          attribute :quiet_time?, QuietTime
          attribute :tags?, Pangea::Resources::Types::Hash.map(Pangea::Resources::Types::String, Pangea::Resources::Types::String)

          def self.from_dynamic(d)
            d = Pangea::Resources::Types::Hash[d]
            
            # Validate quiet time format
            if d[:quiet_time]
              qt = d[:quiet_time]
              if qt[:start] && !qt[:start].match?(/^\d{2}:\d{2}$/)
                raise ArgumentError, "quiet_time.start must be in HH:MM format"
              end
              if qt[:end] && !qt[:end].match?(/^\d{2}:\d{2}$/)
                raise ArgumentError, "quiet_time.end must be in HH:MM format"
              end
            end

            new(
              name: d.fetch(:name),
              name_prefix: d[:name_prefix],
              campaign_hook: d[:campaign_hook] ? CampaignHook.from_dynamic(d[:campaign_hook]) : nil,
              limits: d[:limits] ? Limits.from_dynamic(d[:limits]) : nil,
              quiet_time: d[:quiet_time] ? QuietTime.from_dynamic(d[:quiet_time]) : nil,
              tags: d[:tags]
            )
          end
        end

        # Reference for Pinpoint app resources
      end
        end
    end
  end
end