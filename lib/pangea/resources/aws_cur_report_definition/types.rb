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

require 'dry-struct'
require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
        # CUR report time units
        CurTimeUnit = Resources::Types::String.constrained(included_in: ['HOURLY', 'DAILY', 'MONTHLY'])
        
        # CUR report formats
        CurFormat = Resources::Types::String.constrained(included_in: ['textORcsv', 'Parquet', 'ORC'])
        
        # CUR compression types
        CurCompression = Resources::Types::String.constrained(included_in: ['ZIP', 'GZIP', 'Parquet'])
        
        # CUR versioning
        CurVersioning = Resources::Types::String.constrained(included_in: ['CREATE_NEW_REPORT', 'OVERWRITE_REPORT'])
        
        # Additional schema elements
        CurSchemaElement = Resources::Types::String.constrained(included_in: ['RESOURCES', 'SPLIT_COST_ALLOCATION_DATA', 'MANUAL_DISCOUNT_COMPATIBILITY'])
        
        class CurReportDefinitionAttributes < Dry::Struct
          transform_keys(&:to_sym)
          
          attribute :report_name, Resources::Types::String.constrained(format: /\A[a-zA-Z0-9_\-\.]{1,256}\z/)
          attribute :time_unit, CurTimeUnit
          attribute :format, CurFormat
          attribute :compression, CurCompression
          attribute :s3_bucket, Resources::Types::String.constrained(format: /\A[a-z0-9][a-z0-9\-\.]{1,61}[a-z0-9]\z/)
          attribute :s3_prefix?, Resources::Types::String.constrained(max_size: 256).optional
          attribute :s3_region, Resources::Types::AwsRegion
          attribute :additional_schema_elements?, Resources::Types::Array.of(CurSchemaElement).optional
          attribute :additional_artifacts?, Resources::Types::Array.of(Resources::Types::String.constrained(included_in: ['REDSHIFT', 'QUICKSIGHT', 'ATHENA'])).optional
          attribute :refresh_closed_reports?, Resources::Types::Bool.default(true).optional
          attribute :report_versioning?, CurVersioning.default('CREATE_NEW_REPORT').optional
          attribute :tags?, Resources::Types::AwsTags.optional
          
          def is_hourly?
            time_unit == 'HOURLY'
          end
          
          def has_additional_artifacts?
            additional_artifacts && !additional_artifacts.empty?
          end
          
          def supports_athena?
            additional_artifacts&.include?('ATHENA')
          end
          
          def estimated_monthly_size_gb
            case time_unit
            when 'HOURLY' then 50
            when 'DAILY' then 25
            when 'MONTHLY' then 10
            end
          end
        end
      end
    end
  end
end