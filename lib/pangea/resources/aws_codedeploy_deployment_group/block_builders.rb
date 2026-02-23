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
      # Block builders for AWS CodeDeploy Deployment Group resource
      # Extracts complex nested block logic for maintainability
      module CodeDeployDeploymentGroupBlockBuilders
        private

        def build_blue_green_deployment_config(context, config)
          context.blue_green_deployment_config do
            if config[:terminate_blue_instances_on_deployment_success]
              terminate_cfg = config[:terminate_blue_instances_on_deployment_success]
              context.terminate_blue_instances_on_deployment_success do
                context.action terminate_cfg[:action] if terminate_cfg[:action]
                context.termination_wait_time_in_minutes terminate_cfg[:termination_wait_time_in_minutes] if terminate_cfg[:termination_wait_time_in_minutes]
              end
            end

            if config[:deployment_ready_option]
              context.deployment_ready_option do
                context.action_on_timeout config[:deployment_ready_option][:action_on_timeout] if config[:deployment_ready_option][:action_on_timeout]
              end
            end

            if config[:green_fleet_provisioning_option]
              context.green_fleet_provisioning_option do
                context.action config[:green_fleet_provisioning_option][:action] if config[:green_fleet_provisioning_option][:action]
              end
            end
          end
        end

        def build_load_balancer_info(context, lb_info)
          context.load_balancer_info do
            build_elb_info(context, lb_info[:elb_info]) if lb_info[:elb_info]
            build_target_group_info(context, lb_info[:target_group_info]) if lb_info[:target_group_info]
            build_target_group_pair_info(context, lb_info[:target_group_pair_info]) if lb_info[:target_group_pair_info]
          end
        end

        def build_elb_info(context, elb_list)
          elb_list.each do |elb|
            context.elb_info do
              context.name elb[:name] if elb[:name]
            end
          end
        end

        def build_target_group_info(context, tg_list)
          tg_list.each do |tg|
            context.target_group_info do
              context.name tg[:name] if tg[:name]
            end
          end
        end

        def build_target_group_pair_info(context, pairs)
          pairs.each do |pair|
            context.target_group_pair_info do
              build_prod_traffic_route(context, pair[:prod_traffic_route]) if pair[:prod_traffic_route]
              build_test_traffic_route(context, pair[:test_traffic_route]) if pair[:test_traffic_route]
              build_target_groups(context, pair[:target_groups]) if pair[:target_groups]
            end
          end
        end

        def build_prod_traffic_route(context, route)
          context.prod_traffic_route do
            context.listener_arns route[:listener_arns] if route[:listener_arns]
          end
        end

        def build_test_traffic_route(context, route)
          context.test_traffic_route do
            context.listener_arns route[:listener_arns] if route[:listener_arns]
          end
        end

        def build_target_groups(context, groups)
          groups.each do |tg|
            context.target_group do
              context.name tg[:name] if tg[:name]
            end
          end
        end
      end
    end
  end
end
