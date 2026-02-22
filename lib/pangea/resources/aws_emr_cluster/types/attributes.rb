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
      module Types
        # Type-safe attributes for AWS EMR Cluster resources
        class EmrClusterAttributes < Dry::Struct
          extend EmrClusterClassMethods
          include EmrClusterInstanceMethods
          extend EmrClusterValidation

          attribute :name, Resources::Types::String
          attribute :release_label, Resources::Types::String
          attribute :applications, Resources::Types::Array.of(
            Resources::Types::String.constrained(included_in: ['Hadoop', 'Spark', 'Hive', 'Presto', 'Trino', 'HBase', 'Phoenix', 'Pig',
                               'Sqoop', 'Oozie', 'ZooKeeper', 'Tez', 'Ganglia', 'Flume', 'MXNet',
                               'TensorFlow', 'JupyterHub', 'Livy', 'Zeppelin'])
          ).default(%w[Hadoop Spark].freeze)
          attribute :service_role, Resources::Types::String
          attribute :configurations, Resources::Types::Array.of(
            Resources::Types::Hash.schema(classification: Resources::Types::String, configurations?: Resources::Types::Array.of(Resources::Types::Hash).optional,
                               properties?: Resources::Types::Hash.map(Resources::Types::String, Resources::Types::String).optional)
          ).default([].freeze)

          # EC2 attributes
          attribute :ec2_attributes, Resources::Types::Hash.schema(
            key_name?: Resources::Types::String.optional, instance_profile: Resources::Types::String,
            emr_managed_master_security_group?: Resources::Types::String.optional, emr_managed_slave_security_group?: Resources::Types::String.optional,
            service_access_security_group?: Resources::Types::String.optional, additional_master_security_groups?: Resources::Types::Array.of(Resources::Types::String).optional,
            additional_slave_security_groups?: Resources::Types::Array.of(Resources::Types::String).optional, subnet_id?: Resources::Types::String.optional,
            subnet_ids?: Resources::Types::Array.of(Resources::Types::String).optional
          )

          # Instance groups
          attribute :master_instance_group, Resources::Types::Hash.schema(instance_type: Resources::Types::String, instance_count?: Resources::Types::Integer.constrained(eql: 1).optional)
          attribute :core_instance_group, Resources::Types::Hash.schema(
            instance_type: Resources::Types::String, instance_count?: Resources::Types::Integer.constrained(gteq: 1).optional, bid_price?: Resources::Types::String.optional,
            ebs_config?: Resources::Types::Hash.schema(ebs_block_device_config?: Resources::Types::Array.of(Resources::Types::Hash).optional, ebs_optimized?: Resources::Types::Bool.optional).optional
          ).optional
          attribute :task_instance_groups, Resources::Types::Array.of(Resources::Types::Hash).default([].freeze)

          # Bootstrap and logging
          attribute :bootstrap_action, Resources::Types::Array.of(
            Resources::Types::Hash.schema(path: Resources::Types::String, name: Resources::Types::String, args?: Resources::Types::Array.of(Resources::Types::String).optional)
          ).default([].freeze)
          attribute :log_uri, Resources::Types::String.optional
          attribute :log_encryption_kms_key_id, Resources::Types::String.optional

          # Cluster behavior
          attribute :termination_protection, Resources::Types::Bool.default(false)
          attribute :keep_job_flow_alive_when_no_steps, Resources::Types::Bool.default(true)
          attribute :visible_to_all_users, Resources::Types::Bool.default(true)
          attribute :auto_termination_policy, Resources::Types::Hash.schema(idle_timeout?: Resources::Types::Integer.optional).optional
          attribute :custom_ami_id, Resources::Types::String.optional
          attribute :ebs_root_volume_size, Resources::Types::Integer.optional

          # Kerberos and advanced settings
          attribute :kerberos_attributes, Resources::Types::Hash.schema(
            kdc_admin_password: Resources::Types::String, realm: Resources::Types::String, ad_domain_join_password?: Resources::Types::String.optional,
            ad_domain_join_user?: Resources::Types::String.optional, cross_realm_trust_principal_password?: Resources::Types::String.optional
          ).optional
          attribute :step_concurrency_level, Resources::Types::Integer.constrained(gteq: 1, lteq: 256).optional
          attribute :placement_group_configs, Resources::Types::Array.of(
            Resources::Types::Hash.schema(instance_role: Resources::Types::String.constrained(included_in: ['MASTER', 'CORE', 'TASK']), placement_strategy?: Resources::Types::String.constrained(included_in: ['SPREAD', 'PARTITION', 'CLUSTER']).optional)
          ).default([].freeze)
          attribute :tags, Resources::Types::AwsTags.default({}.freeze)

          def self.new(attributes = {})
            attrs = super(attributes)
            validate_cluster_name(attrs.name)
            validate_release_label(attrs.release_label)
            validate_service_role(attrs.service_role)
            validate_instance_profile(attrs.ec2_attributes[:instance_profile])
            validate_log_uri(attrs.log_uri)
            validate_subnet_config(attrs.ec2_attributes)
            attrs
          end
        end
      end
    end
  end
end
