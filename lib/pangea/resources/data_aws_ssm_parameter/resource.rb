# frozen_string_literal: true

require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/data_aws_ssm_parameter/types'
require 'pangea/resource_registry'

module Pangea::Resources
  module AWSDataSsmParameter
    include Pangea::Resources::ResourceBuilder

    define_data :aws_ssm_parameter,
      attributes_class: AWS::Types::DataSsmParameterAttributes,
      outputs: { id: :id, value: :value, type: :type, arn: :arn, version: :version },
      map: [:name],
      map_bool: [:with_decryption]
  end
  module AWS
    include AWSDataSsmParameter
  end
end
Pangea::ResourceRegistry.register_module(Pangea::Resources::AWS)
