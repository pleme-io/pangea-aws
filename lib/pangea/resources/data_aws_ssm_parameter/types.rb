# frozen_string_literal: true

require 'dry-struct'

module Pangea::Resources::AWS::Types
  include Dry.Types()

  class DataSsmParameterAttributes < Dry::Struct
    transform_keys(&:to_sym)
    T = Pangea::Resources::AWS::Types

    attribute :name, T::String
    attribute? :with_decryption, T::Bool.optional
  end
end
