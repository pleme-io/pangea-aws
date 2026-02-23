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
      module WafV2WebAcl
        class DSLBuilder
          # Field to match building methods
          module FieldToMatch
            def build_field_to_match(ctx, config)
              if config[:all_query_arguments]
                ctx.all_query_arguments
              elsif config[:body]
                ctx.body do
                  ctx.oversize_handling config[:body][:oversize_handling] if config[:body][:oversize_handling]
                end
              elsif config[:method]
                ctx.method
              elsif config[:query_string]
                ctx.query_string
              elsif config[:single_header]
                ctx.single_header do
                  ctx.name config[:single_header][:name]
                end
              elsif config[:single_query_argument]
                ctx.single_query_argument do
                  ctx.name config[:single_query_argument][:name]
                end
              elsif config[:uri_path]
                ctx.uri_path
              elsif config[:json_body]
                build_json_body(ctx, config[:json_body])
              end
            end

            private

            def build_json_body(ctx, config)
              ctx.json_body do
                ctx.match_scope config[:match_scope]
                ctx.match_pattern do
                  if config[:match_pattern][:all]
                    ctx.all
                  elsif config[:match_pattern][:included_paths]
                    config[:match_pattern][:included_paths].each { |path| ctx.included_paths path }
                  end
                end
                ctx.invalid_fallback_behavior config[:invalid_fallback_behavior] if config[:invalid_fallback_behavior]
                ctx.oversize_handling config[:oversize_handling] if config[:oversize_handling]
              end
            end
          end
        end
      end
    end
  end
end
