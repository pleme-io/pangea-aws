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
          # Rule building methods
          module Rules
            def build_rules(ctx)
              attrs.rules.each { |rule_attrs| build_single_rule(ctx, rule_attrs) }
            end

            def build_single_rule(ctx, rule_attrs)
              builder = self
              ctx.rule do
                ctx.name rule_attrs.name
                ctx.priority rule_attrs.priority
                builder.build_rule_action(ctx, rule_attrs.action)
                ctx.statement { builder.build_statement(ctx, rule_attrs.statement) }
                builder.build_visibility_config(ctx, rule_attrs.visibility_config)
                builder.build_rule_labels(ctx, rule_attrs.rule_labels)
                builder.build_captcha_config(ctx, rule_attrs.captcha_config)
                builder.build_challenge_config(ctx, rule_attrs.challenge_config)
              end
            end

            def build_rule_action(ctx, action)
              builder = self
              ctx.action do
                if action.allow
                  ctx.allow do
                    builder.build_custom_request_handling(ctx, action.allow[:custom_request_handling])
                  end
                elsif action.block
                  ctx.block do
                    builder.build_custom_response(ctx, action.block[:custom_response])
                  end
                elsif action.count
                  ctx.count do
                    builder.build_custom_request_handling(ctx, action.count[:custom_request_handling])
                  end
                elsif action.captcha
                  ctx.captcha do
                    builder.build_custom_request_handling(ctx, action.captcha[:custom_request_handling])
                  end
                elsif action.challenge
                  ctx.challenge do
                    builder.build_custom_request_handling(ctx, action.challenge[:custom_request_handling])
                  end
                end
              end
            end

            def build_visibility_config(ctx, config)
              ctx.visibility_config do
                ctx.cloudwatch_metrics_enabled config.cloudwatch_metrics_enabled
                ctx.metric_name config.metric_name
                ctx.sampled_requests_enabled config.sampled_requests_enabled
              end
            end

            def build_rule_labels(ctx, labels)
              return unless labels.any?

              labels.each do |label|
                ctx.rule_label do
                  ctx.name label[:name]
                end
              end
            end

            def build_captcha_config(ctx, config)
              return unless config

              ctx.captcha_config do
                ctx.immunity_time_property do
                  ctx.immunity_time config[:immunity_time_property][:immunity_time]
                end
              end
            end

            def build_challenge_config(ctx, config)
              return unless config

              ctx.challenge_config do
                ctx.immunity_time_property do
                  ctx.immunity_time config[:immunity_time_property][:immunity_time]
                end
              end
            end
          end
        end
      end
    end
  end
end
