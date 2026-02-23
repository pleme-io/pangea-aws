# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
        # Cognito identity provider configuration for identity pool
        class CognitoIdentityPoolProvider < Pangea::Resources::BaseAttributes
          attribute? :client_id, Resources::Types::String.optional
          attribute? :provider_name, Resources::Types::String.optional
          attribute? :server_side_token_check, Resources::Types::Bool.optional
        end

        # SAML identity provider configuration
        class SamlIdentityProvider < Pangea::Resources::BaseAttributes
          attribute? :provider_name, Resources::Types::String.optional
          attribute? :provider_arn, Resources::Types::String.optional
        end

        # OpenID Connect identity provider configuration
        class OpenIdConnectProvider < Pangea::Resources::BaseAttributes
          attribute? :provider_name, Resources::Types::String.optional
          attribute? :provider_arn, Resources::Types::String.optional
        end

        # Developer authenticated identities configuration
        class DeveloperProvider < Pangea::Resources::BaseAttributes
          attribute? :provider_name, Resources::Types::String.optional
          attribute? :developer_user_identifier_name, Resources::Types::String.optional
        end
      end
    end
  end
end
