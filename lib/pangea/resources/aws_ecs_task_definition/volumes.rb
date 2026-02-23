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
      module EcsTaskDefinition
        # Configures volume blocks for ECS task definitions
        module Volumes
          extend self

          # Configure volumes in the resource block context
          # @param context [Object] The resource block context
          # @param volumes [Array] Array of volume configurations
          def configure(context, volumes)
            volumes.each do |vol|
              context.volume do |v|
                v.name vol[:name]
                configure_host_volume(v, vol)
                configure_docker_volume(v, vol)
                configure_efs_volume(v, vol)
                configure_fsx_volume(v, vol)
              end
            end
          end

          private

          def configure_host_volume(context, vol)
            return unless vol[:host]

            context.host do |h|
              h.source_path vol[:host][:source_path] if vol[:host][:source_path]
            end
          end

          def configure_docker_volume(context, vol)
            dvc = vol[:docker_volume_configuration]
            return unless dvc

            context.docker_volume_configuration do |d|
              d.scope dvc[:scope] if dvc[:scope]
              d.autoprovision dvc[:autoprovision] unless dvc[:autoprovision].nil?
              d.driver dvc[:driver] if dvc[:driver]
              d.driver_opts dvc[:driver_opts] if dvc[:driver_opts]
              d.labels dvc[:labels] if dvc[:labels]
            end
          end

          def configure_efs_volume(context, vol)
            evc = vol[:efs_volume_configuration]
            return unless evc

            context.efs_volume_configuration do |e|
              e.file_system_id evc[:file_system_id]
              e.root_directory evc[:root_directory] if evc[:root_directory]
              e.transit_encryption evc[:transit_encryption] if evc[:transit_encryption]
              e.transit_encryption_port evc[:transit_encryption_port] if evc[:transit_encryption_port]

              configure_efs_authorization(e, evc)
            end
          end

          def configure_efs_authorization(context, evc)
            auth = evc[:authorization_config]
            return unless auth

            context.authorization_config do |a|
              a.access_point_id auth[:access_point_id] if auth[:access_point_id]
              a.iam auth[:iam] if auth[:iam]
            end
          end

          def configure_fsx_volume(context, vol)
            fsx = vol[:fsx_windows_file_server_volume_configuration]
            return unless fsx

            context.fsx_windows_file_server_volume_configuration do |f|
              f.file_system_id fsx[:file_system_id]
              f.root_directory fsx[:root_directory]

              f.authorization_config do |a|
                a.credentials_parameter fsx[:authorization_config][:credentials_parameter]
                a.domain fsx[:authorization_config][:domain]
              end
            end
          end
        end
      end
    end
  end
end
