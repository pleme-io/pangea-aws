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

require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/aws_dynamodb_table/types'
require 'pangea/resource_registry'
require_relative 'builders/table_builder'
require_relative 'builders/reference_builder'

module Pangea
  module Resources
    module AWS
      # Create an AWS DynamoDB Table with type-safe attributes
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] DynamoDB table attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_dynamodb_table(name, attributes = {})
        table_attrs = Types::DynamoDbTableAttributes.new(attributes)

        resource(:aws_dynamodb_table, name) do
          # Basic settings
          table_name table_attrs.name
          billing_mode table_attrs.billing_mode
          hash_key table_attrs.hash_key
          range_key table_attrs.range_key if table_attrs.range_key

          # Attribute definitions (array of hashes)
          attribute table_attrs.attribute.map { |attr_def|
            { name: attr_def[:name], type: attr_def[:type] }
          }

          # Provisioned capacity
          if table_attrs.is_provisioned?
            read_capacity table_attrs.read_capacity
            write_capacity table_attrs.write_capacity
          end

          # Global Secondary Indexes (array of hashes)
          if table_attrs.global_secondary_index.any?
            global_secondary_index table_attrs.global_secondary_index.map { |gsi|
              gh = { name: gsi[:name], hash_key: gsi[:hash_key], projection_type: gsi[:projection_type] }
              gh[:range_key] = gsi[:range_key] if gsi[:range_key]
              gh[:non_key_attributes] = gsi[:non_key_attributes] if gsi[:non_key_attributes]
              if table_attrs.is_provisioned?
                gh[:read_capacity] = gsi[:read_capacity]
                gh[:write_capacity] = gsi[:write_capacity]
              end
              gh
            }
          end

          # Local Secondary Indexes (array of hashes)
          if table_attrs.local_secondary_index.any?
            local_secondary_index table_attrs.local_secondary_index.map { |lsi|
              lh = { name: lsi[:name], range_key: lsi[:range_key], projection_type: lsi[:projection_type] }
              lh[:non_key_attributes] = lsi[:non_key_attributes] if lsi[:non_key_attributes]
              lh
            }
          end

          # TTL
          if table_attrs.ttl
            ttl({ attribute_name: table_attrs.ttl[:attribute_name], enabled: table_attrs.ttl[:enabled] })
          end

          # Streams
          if table_attrs.stream_enabled
            stream_enabled table_attrs.stream_enabled
            stream_view_type table_attrs.stream_view_type
          end

          # Point-in-time recovery
          point_in_time_recovery({ enabled: table_attrs.point_in_time_recovery_enabled })

          # Server-side encryption
          if table_attrs.server_side_encryption
            sse = table_attrs.server_side_encryption
            sse_hash = { enabled: sse[:enabled] }
            sse_hash[:kms_key_id] = sse[:kms_key_id] if sse[:kms_key_id]
            server_side_encryption sse_hash
          end

          # Table settings
          deletion_protection_enabled table_attrs.deletion_protection_enabled
          table_class table_attrs.table_class

          # Restore configuration
          if table_attrs.restore_source_name
            restore_source_name table_attrs.restore_source_name
          elsif table_attrs.restore_source_table_arn
            restore_source_table_arn table_attrs.restore_source_table_arn
            restore_to_time table_attrs.restore_to_time if table_attrs.restore_to_time
            restore_date_time table_attrs.restore_date_time if table_attrs.restore_date_time
          end

          # Import table configuration
          if table_attrs.import_table
            imp = table_attrs.import_table
            import_hash = { input_format: imp[:input_format] }

            if imp[:s3_bucket_source]
              s3_hash = { bucket: imp[:s3_bucket_source][:bucket] }
              s3_hash[:bucket_owner] = imp[:s3_bucket_source][:bucket_owner] if imp[:s3_bucket_source][:bucket_owner]
              s3_hash[:key_prefix] = imp[:s3_bucket_source][:key_prefix] if imp[:s3_bucket_source][:key_prefix]
              import_hash[:s3_bucket_source] = s3_hash
            end

            if imp[:input_format_options]&.dig(:csv)
              csv_opts = imp[:input_format_options][:csv]
              csv_hash = {}
              csv_hash[:delimiter] = csv_opts[:delimiter] if csv_opts[:delimiter]
              csv_hash[:header_list] = csv_opts[:header_list] if csv_opts[:header_list]
              import_hash[:input_format_options] = { csv: csv_hash }
            end

            import_hash[:input_compression_type] = imp[:input_compression_type] if imp[:input_compression_type]
            import_table import_hash
          end

          # Replicas (array of hashes)
          if table_attrs.replica.any?
            replica table_attrs.replica.map { |rep|
              rh = { region_name: rep[:region_name] }
              rh[:kms_key_id] = rep[:kms_key_id] if rep[:kms_key_id]
              rh[:point_in_time_recovery] = rep[:point_in_time_recovery] if rep[:point_in_time_recovery]
              rh[:table_class] = rep[:table_class] if rep[:table_class]
              if rep[:global_secondary_index]
                rh[:global_secondary_index] = rep[:global_secondary_index].map { |rgsi|
                  rgh = { name: rgsi[:name] }
                  rgh[:read_capacity] = rgsi[:read_capacity] if rgsi[:read_capacity]
                  rgh[:write_capacity] = rgsi[:write_capacity] if rgsi[:write_capacity]
                  rgh
                }
              end
              rh
            }
          end

          # Tags
          tags table_attrs.tags if table_attrs.tags.any?
        end

        DynamoDBTable::ReferenceBuilder.build_reference(name, table_attrs)
      end
    end
  end
end
