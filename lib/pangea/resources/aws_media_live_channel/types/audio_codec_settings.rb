# frozen_string_literal: true

require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
        module MediaLiveChannel
            T = Resources::Types

          # Audio codec and description type definitions

          module AudioCodecSettings
            T = Resources::Types

            # AAC codec settings
            AacSettings = T::Hash.schema(
              bitrate?: T::Float.optional,
              coding_mode?: T::String.constrained(included_in: ['AD_RECEIVER_MIX', 'CODING_MODE_1_0', 'CODING_MODE_1_1', 'CODING_MODE_2_0', 'CODING_MODE_5_1']).optional,
              input_type?: T::String.constrained(included_in: ['BROADCASTER_MIXED_AD', 'NORMAL']).optional,
              profile?: T::String.constrained(included_in: ['HEV1', 'HEV2', 'LC']).optional,
              rate_control_mode?: T::String.constrained(included_in: ['CBR', 'VBR']).optional,
              raw_format?: T::String.constrained(included_in: ['LATM_LOAS', 'NONE']).optional,
              sample_rate?: T::Float.optional,
              spec?: T::String.constrained(included_in: ['MPEG2', 'MPEG4']).optional,
              vbr_quality?: T::String.constrained(included_in: ['HIGH', 'LOW', 'MEDIUM_HIGH', 'MEDIUM_LOW']).optional
            ).lax

            # AC3 codec settings
            Ac3Settings = T::Hash.schema(
              bitrate?: T::Float.optional,
              bitstream_mode?: T::String.constrained(included_in: ['COMMENTARY', 'COMPLETE_MAIN', 'DIALOGUE', 'EMERGENCY', 'HEARING_IMPAIRED', 'MUSIC_AND_EFFECTS', 'VISUALLY_IMPAIRED', 'VOICE_OVER']).optional,
              coding_mode?: T::String.constrained(included_in: ['CODING_MODE_1_0', 'CODING_MODE_1_1', 'CODING_MODE_2_0', 'CODING_MODE_3_2_LFE']).optional,
              dialnorm?: T::Integer.optional,
              drc_profile?: T::String.constrained(included_in: ['FILM_STANDARD', 'NONE']).optional,
              lfe_filter?: T::String.constrained(included_in: ['DISABLED', 'ENABLED']).optional,
              metadata_control?: T::String.constrained(included_in: ['FOLLOW_INPUT', 'USE_CONFIGURED']).optional
            ).lax

            # EAC3 codec settings
            Eac3Settings = T::Hash.schema(
              attenuation_control?: T::String.constrained(included_in: ['ATTENUATE_3_DB', 'NONE']).optional,
              bitrate?: T::Float.optional,
              bitstream_mode?: T::String.constrained(included_in: ['COMMENTARY', 'COMPLETE_MAIN', 'EMERGENCY', 'HEARING_IMPAIRED', 'VISUALLY_IMPAIRED']).optional,
              coding_mode?: T::String.constrained(included_in: ['CODING_MODE_1_0', 'CODING_MODE_2_0', 'CODING_MODE_3_2']).optional,
              dc_filter?: T::String.constrained(included_in: ['DISABLED', 'ENABLED']).optional,
              dialnorm?: T::Integer.optional,
              drc_line?: T::String.constrained(included_in: ['FILM_LIGHT', 'FILM_STANDARD', 'MUSIC_LIGHT', 'MUSIC_STANDARD', 'NONE', 'SPEECH']).optional,
              drc_rf?: T::String.constrained(included_in: ['FILM_LIGHT', 'FILM_STANDARD', 'MUSIC_LIGHT', 'MUSIC_STANDARD', 'NONE', 'SPEECH']).optional,
              lfe_control?: T::String.constrained(included_in: ['LFE', 'NO_LFE']).optional,
              lfe_filter?: T::String.constrained(included_in: ['DISABLED', 'ENABLED']).optional,
              lo_ro_center_mix_level?: T::Float.optional,
              lo_ro_surround_mix_level?: T::Float.optional,
              lt_rt_center_mix_level?: T::Float.optional,
              lt_rt_surround_mix_level?: T::Float.optional,
              metadata_control?: T::String.constrained(included_in: ['FOLLOW_INPUT', 'USE_CONFIGURED']).optional,
              passthrough_control?: T::String.constrained(included_in: ['NO_PASSTHROUGH', 'WHEN_POSSIBLE']).optional,
              phase_control?: T::String.constrained(included_in: ['NO_SHIFT', 'SHIFT_90_DEGREES']).optional,
              stereo_downmix?: T::String.constrained(included_in: ['DPL2', 'LO_RO', 'LT_RT', 'NOT_INDICATED']).optional,
              surround_ex_mode?: T::String.constrained(included_in: ['DISABLED', 'ENABLED', 'NOT_INDICATED']).optional,
              surround_mode?: T::String.constrained(included_in: ['DISABLED', 'ENABLED', 'NOT_INDICATED']).optional
            ).lax

            # Codec settings container
            CodecSettings = T::Hash.schema(
              aac_settings?: AacSettings.optional,
              ac3_settings?: Ac3Settings.optional,
              eac3_settings?: Eac3Settings.optional
            ).lax

            # Remix settings
            ChannelMapping = T::Hash.schema(
              input_channel_levels: T::Array.of(
                T::Hash.schema(
                  gain: T::Integer,
                  input_channel: T::Integer
                ).lax
              ),
              output_channel: T::Integer
            )

            RemixSettings = T::Hash.schema(
              channel_mappings: T::Array.of(ChannelMapping),
              channels_in?: T::Integer.optional,
              channels_out?: T::Integer.optional
            ).lax

            # Audio description
            AudioDescription = T::Hash.schema(
              audio_selector_name: T::String,
              audio_type?: T::String.constrained(included_in: ['CLEAN_EFFECTS', 'HEARING_IMPAIRED', 'UNDEFINED', 'VISUAL_IMPAIRED_COMMENTARY']).optional,
              audio_type_control?: T::String.constrained(included_in: ['FOLLOW_INPUT', 'USE_CONFIGURED']).optional,
              codec_settings?: CodecSettings.optional,
              language_code?: T::String.optional,
              language_code_control?: T::String.constrained(included_in: ['FOLLOW_INPUT', 'USE_CONFIGURED']).optional,
              name: T::String,
              remix_settings?: RemixSettings.optional,
              stream_name?: T::String.optional
            ).lax
          end
        end
      end
    end
  end
end
