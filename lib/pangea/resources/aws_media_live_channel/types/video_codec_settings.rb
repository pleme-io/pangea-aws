# frozen_string_literal: true

require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
        module MediaLiveChannel
            T = Resources::Types

          # Video codec type definitions

          module VideoCodecSettings
            T = Resources::Types

            # Temporal filter settings (shared)
            TemporalFilterSettings = T::Hash.schema(
              post_filter_sharpening?: T::String.constrained(included_in: ['AUTO', 'DISABLED', 'ENABLED']).optional,
              strength?: T::String.constrained(included_in: ['AUTO', 'STRENGTH_1', 'STRENGTH_2', 'STRENGTH_3', 'STRENGTH_4', 'STRENGTH_5', 'STRENGTH_6', 'STRENGTH_7', 'STRENGTH_8', 'STRENGTH_9', 'STRENGTH_10', 'STRENGTH_11', 'STRENGTH_12', 'STRENGTH_13', 'STRENGTH_14', 'STRENGTH_15', 'STRENGTH_16']).optional
            ).lax

            # Timecode burnin settings (shared)
            TimecodeBurninSettings = T::Hash.schema(
              font_size?: T::String.constrained(included_in: ['EXTRA_SMALL_10', 'LARGE_48', 'MEDIUM_16', 'SMALL_12']).optional,
              position?: T::String.constrained(included_in: ['BOTTOM_CENTER', 'BOTTOM_LEFT', 'BOTTOM_RIGHT', 'MIDDLE_CENTER', 'MIDDLE_LEFT', 'MIDDLE_RIGHT', 'TOP_CENTER', 'TOP_LEFT', 'TOP_RIGHT']).optional,
              prefix?: T::String.optional
            ).lax

            # AFD values enum
            AfdValues = T::String.constrained(included_in: ['AFD_0000', 'AFD_0010', 'AFD_0011', 'AFD_0100', 'AFD_1000', 'AFD_1001', 'AFD_1010', 'AFD_1011', 'AFD_1101', 'AFD_1110', 'AFD_1111'])

            # Filter settings
            FilterSettings = T::Hash.schema(
              temporal_filter_settings?: TemporalFilterSettings.optional
            ).lax

            # Frame capture settings
            FrameCaptureSettings = T::Hash.schema(
              capture_interval?: T::Integer.optional,
              capture_interval_units?: T::String.constrained(included_in: ['MILLISECONDS', 'SECONDS']).optional
            ).lax

            # H264 settings
            H264Settings = T::Hash.schema(
              adaptive_quantization?: T::String.constrained(included_in: ['AUTO', 'HIGH', 'HIGHER', 'LOW', 'MAX', 'MEDIUM', 'OFF']).optional,
              afd_signaling?: T::String.constrained(included_in: ['AUTO', 'FIXED', 'NONE']).optional,
              bitrate?: T::Integer.optional,
              buf_fill_pct?: T::Integer.optional,
              buf_size?: T::Integer.optional,
              color_metadata?: T::String.constrained(included_in: ['IGNORE', 'INSERT']).optional,
              entropy_encoding?: T::String.constrained(included_in: ['CABAC', 'CAVLC']).optional,
              filter_settings?: FilterSettings.optional,
              fixed_afd?: AfdValues.optional,
              flicker_aq?: T::String.constrained(included_in: ['DISABLED', 'ENABLED']).optional,
              force_field_pictures?: T::String.constrained(included_in: ['DISABLED', 'ENABLED']).optional,
              framerate_control?: T::String.constrained(included_in: ['INITIALIZE_FROM_SOURCE', 'SPECIFIED']).optional,
              framerate_denominator?: T::Integer.optional,
              framerate_numerator?: T::Integer.optional,
              gop_b_reference?: T::String.constrained(included_in: ['DISABLED', 'ENABLED']).optional,
              gop_closed_cadence?: T::Integer.optional,
              gop_num_b_frames?: T::Integer.optional,
              gop_size?: T::Float.optional,
              gop_size_units?: T::String.constrained(included_in: ['FRAMES', 'SECONDS']).optional,
              level?: T::String.constrained(included_in: ['H264_LEVEL_1', 'H264_LEVEL_1_1', 'H264_LEVEL_1_2', 'H264_LEVEL_1_3', 'H264_LEVEL_2', 'H264_LEVEL_2_1', 'H264_LEVEL_2_2', 'H264_LEVEL_3', 'H264_LEVEL_3_1', 'H264_LEVEL_3_2', 'H264_LEVEL_4', 'H264_LEVEL_4_1', 'H264_LEVEL_4_2', 'H264_LEVEL_5', 'H264_LEVEL_5_1', 'H264_LEVEL_5_2', 'H264_LEVEL_AUTO']).optional,
              look_ahead_rate_control?: T::String.constrained(included_in: ['HIGH', 'LOW', 'MEDIUM']).optional,
              max_bitrate?: T::Integer.optional,
              min_i_interval?: T::Integer.optional,
              num_ref_frames?: T::Integer.optional,
              par_control?: T::String.constrained(included_in: ['INITIALIZE_FROM_SOURCE', 'SPECIFIED']).optional,
              par_denominator?: T::Integer.optional,
              par_numerator?: T::Integer.optional,
              profile?: T::String.constrained(included_in: ['BASELINE', 'HIGH', 'HIGH_10BIT', 'HIGH_422', 'HIGH_422_10BIT', 'MAIN']).optional,
              quality_level?: T::String.constrained(included_in: ['ENHANCED_QUALITY', 'STANDARD_QUALITY']).optional,
              qvbr_quality_level?: T::Integer.optional,
              rate_control_mode?: T::String.constrained(included_in: ['CBR', 'MULTIPLEX', 'QVBR', 'VBR']).optional,
              scan_type?: T::String.constrained(included_in: ['INTERLACED', 'PROGRESSIVE']).optional,
              scene_change_detect?: T::String.constrained(included_in: ['DISABLED', 'ENABLED']).optional,
              slices?: T::Integer.optional,
              softness?: T::Integer.optional,
              spatial_aq?: T::String.constrained(included_in: ['DISABLED', 'ENABLED']).optional,
              subgop_length?: T::String.constrained(included_in: ['DYNAMIC', 'FIXED']).optional,
              syntax?: T::String.constrained(included_in: ['DEFAULT', 'RP2027']).optional,
              temporal_aq?: T::String.constrained(included_in: ['DISABLED', 'ENABLED']).optional,
              timecode_insertion?: T::String.constrained(included_in: ['DISABLED', 'PIC_TIMING_SEI']).optional,
              timecode_burnin_settings?: TimecodeBurninSettings.optional
            ).lax
          end
        end
      end
    end
  end
end
