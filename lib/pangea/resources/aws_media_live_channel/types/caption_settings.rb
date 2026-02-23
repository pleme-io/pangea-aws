# frozen_string_literal: true

require 'pangea/resources/types'
require_relative 'encoder_config'

module Pangea
  module Resources
    module AWS
      module Types
        module MediaLiveChannel
            T = Resources::Types

          # Caption type definitions

          module CaptionSettings
            T = Resources::Types
            EC = EncoderConfig

            # Font settings (shared for burn-in and DVB-sub)
            FontColorEnum = T::String.constrained(included_in: ['BLACK', 'BLUE', 'GREEN', 'RED', 'WHITE', 'YELLOW'])
            BackgroundColorEnum = T::String.constrained(included_in: ['BLACK', 'NONE', 'WHITE'])
            ShadowColorEnum = T::String.constrained(included_in: ['BLACK', 'NONE', 'WHITE'])
            AlignmentEnum = T::String.constrained(included_in: ['CENTERED', 'LEFT', 'SMART'])

            # Burn-in destination settings
            BurnInDestinationSettings = T::Hash.schema(
              alignment?: AlignmentEnum.optional,
              background_color?: BackgroundColorEnum.optional,
              background_opacity?: T::Integer.optional,
              font?: EC::ImageInput.optional,
              font_color?: FontColorEnum.optional,
              font_opacity?: T::Integer.optional,
              font_resolution?: T::Integer.optional,
              font_size?: T::String.optional,
              outline_color?: FontColorEnum.optional,
              outline_size?: T::Integer.optional,
              shadow_color?: ShadowColorEnum.optional,
              shadow_opacity?: T::Integer.optional,
              shadow_x_offset?: T::Integer.optional,
              shadow_y_offset?: T::Integer.optional,
              teletext_grid_control?: T::String.constrained(included_in: ['FIXED', 'SCALED']).optional,
              x_position?: T::Integer.optional,
              y_position?: T::Integer.optional
            ).lax

            # DVB-sub destination settings
            DvbSubDestinationSettings = T::Hash.schema(
              alignment?: AlignmentEnum.optional,
              background_color?: BackgroundColorEnum.optional,
              background_opacity?: T::Integer.optional,
              font?: EC::ImageInput.optional,
              font_color?: FontColorEnum.optional,
              font_opacity?: T::Integer.optional,
              font_resolution?: T::Integer.optional,
              font_size?: T::String.optional,
              outline_color?: FontColorEnum.optional,
              outline_size?: T::Integer.optional,
              shadow_color?: ShadowColorEnum.optional,
              shadow_opacity?: T::Integer.optional,
              shadow_x_offset?: T::Integer.optional,
              shadow_y_offset?: T::Integer.optional,
              teletext_grid_control?: T::String.constrained(included_in: ['FIXED', 'SCALED']).optional,
              x_position?: T::Integer.optional,
              y_position?: T::Integer.optional
            ).lax

            # EBU TT-D destination settings
            EbuTtDDestinationSettings = T::Hash.schema(
              copyright_holder?: T::String.optional,
              fill_line_gap?: T::String.constrained(included_in: ['DISABLED', 'ENABLED']).optional,
              font_family?: T::String.optional,
              style_control?: T::String.constrained(included_in: ['EXCLUDE', 'INCLUDE']).optional
            ).lax

            # TTML destination settings
            TtmlDestinationSettings = T::Hash.schema(
              style_control?: T::String.constrained(included_in: ['PASSTHROUGH', 'USE_CONFIGURED']).optional
            ).lax

            # WebVTT destination settings
            WebvttDestinationSettings = T::Hash.schema(
              style_control?: T::String.constrained(included_in: ['NO_STYLE_DATA', 'PASSTHROUGH']).optional
            ).lax

            # Caption destination settings container
            DestinationSettings = T::Hash.schema(
              arib_destination_settings?: T::Hash.optional,
              burn_in_destination_settings?: BurnInDestinationSettings.optional,
              dvb_sub_destination_settings?: DvbSubDestinationSettings.optional,
              ebu_tt_d_destination_settings?: EbuTtDDestinationSettings.optional,
              embedded_destination_settings?: T::Hash.optional,
              embedded_plus_scte20_destination_settings?: T::Hash.optional,
              rtmp_caption_info_destination_settings?: T::Hash.optional,
              scte20_plus_embedded_destination_settings?: T::Hash.optional,
              scte27_destination_settings?: T::Hash.optional,
              smpte_tt_destination_settings?: T::Hash.optional,
              teletext_destination_settings?: T::Hash.optional,
              ttml_destination_settings?: TtmlDestinationSettings.optional,
              webvtt_destination_settings?: WebvttDestinationSettings.optional
            ).lax

            # Caption description
            CaptionDescription = T::Hash.schema(
              caption_selector_name: T::String,
              destination_settings?: DestinationSettings.optional,
              language_code?: T::String.optional,
              language_description?: T::String.optional,
              name: T::String
            ).lax


          end
        end
      end
    end
  end
end
