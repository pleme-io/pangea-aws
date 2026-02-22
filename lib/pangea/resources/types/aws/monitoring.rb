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

require_relative 'core'

module Pangea
  module Resources
    module Types
      # GuardDuty types
      GuardDutyFindingPublishingFrequency = Resources::Types::String.constrained(included_in: ['FIFTEEN_MINUTES', 'ONE_HOUR', 'SIX_HOURS'])
      GuardDutyDetectorStatus = Resources::Types::String.constrained(included_in: ['ENABLED', 'DISABLED'])
      GuardDutyDataSourceStatus = Resources::Types::String.constrained(included_in: ['ENABLED', 'DISABLED'])
      GuardDutyThreatIntelSetFormat = Resources::Types::String.constrained(included_in: ['TXT', 'STIX', 'OTX_CSV', 'ALIEN_VAULT', 'PROOF_POINT', 'FIRE_EYE'])
      GuardDutyIpSetFormat = Resources::Types::String.constrained(included_in: ['TXT', 'STIX', 'OTX_CSV', 'ALIEN_VAULT', 'PROOF_POINT', 'FIRE_EYE'])
      GuardDutyMemberStatus = Resources::Types::String.constrained(included_in: ['CREATED', 'INVITED', 'DISABLED', 'ENABLED', 'REMOVED', 'RESIGNED'])
      GuardDutyDetectorArn = String.constrained(format: /\Aarn:aws:guardduty:[a-z0-9-]+:\d{12}:detector\/[a-f0-9]{32}\z/)

      GuardDutyInvitationEmail = String.constrained(format: /\A[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}\z/).constructor { |value|
        if value.length > 320
          raise Dry::Types::ConstraintError, "Email address cannot exceed 320 characters"
        end
        value
      }

      # Inspector v2 types
      InspectorV2ResourceType = Resources::Types::String.constrained(included_in: ['ECR', 'EC2'])
      InspectorV2ScanType = Resources::Types::String.constrained(included_in: ['NETWORK', 'PACKAGE'])
      InspectorV2ScanStatus = Resources::Types::String.constrained(included_in: ['ENABLED', 'DISABLED', 'SUSPENDED'])

      # Security Hub types
      SecurityHubStandardsArn = String.constrained(format: /\Aarn:aws:securityhub:[a-z0-9-]+::\w+\/\w+\/\w+\z/)
      SecurityHubControlStatus = Resources::Types::String.constrained(included_in: ['ENABLED', 'DISABLED'])
      SecurityHubComplianceStatus = Resources::Types::String.constrained(included_in: ['PASSED', 'WARNING', 'FAILED', 'NOT_AVAILABLE'])
      SecurityHubSeverity = Resources::Types::String.constrained(included_in: ['INFORMATIONAL', 'LOW', 'MEDIUM', 'HIGH', 'CRITICAL'])
      SecurityHubRecordState = Resources::Types::String.constrained(included_in: ['ACTIVE', 'ARCHIVED'])
      SecurityHubWorkflowStatus = Resources::Types::String.constrained(included_in: ['NEW', 'NOTIFIED', 'RESOLVED', 'SUPPRESSED'])
      SecurityHubArn = String.constrained(format: /\Aarn:aws:securityhub:[a-z0-9-]+:\d{12}:hub\/default\z/)
    end
  end
end
