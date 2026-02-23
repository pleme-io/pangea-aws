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
        # Storage descriptor type definitions for Glue Catalog Table
        module GlueCatalogTableStorageDescriptor
          # Column schema type
          ColumnSchema = Resources::Types::Hash.schema(
            name: Resources::Types::String,
            type: Resources::Types::String,
            comment?: Resources::Types::String.optional,
            parameters?: Resources::Types::Hash.map(Resources::Types::String, Resources::Types::String).optional
          ).lax

          # SerDe info schema type
          SerdeInfoSchema = Resources::Types::Hash.schema(
            name?: Resources::Types::String.optional,
            serialization_library?: Resources::Types::String.optional,
            parameters?: Resources::Types::Hash.map(Resources::Types::String, Resources::Types::String).optional
          ).lax

          # Sort column schema type
          SortColumnSchema = Resources::Types::Hash.schema(
            column: Resources::Types::String,
            sort_order: Resources::Types::Integer.constrained(included_in: [0, 1])
          ).lax

          # Full storage descriptor schema
          StorageDescriptorSchema = Resources::Types::Hash.schema(
            columns?: Resources::Types::Array.of(ColumnSchema).optional,
            location?: Resources::Types::String.optional,
            input_format?: Resources::Types::String.optional,
            output_format?: Resources::Types::String.optional,
            compressed?: Resources::Types::Bool.optional,
            number_of_buckets?: Resources::Types::Integer.optional,
            serde_info?: SerdeInfoSchema.optional,
            bucket_columns?: Resources::Types::Array.of(Resources::Types::String).optional,
            sort_columns?: Resources::Types::Array.of(SortColumnSchema).optional,
            stored_as_sub_directories?: Resources::Types::Bool.optional
          ).lax
        end
      end
    end
  end
end
