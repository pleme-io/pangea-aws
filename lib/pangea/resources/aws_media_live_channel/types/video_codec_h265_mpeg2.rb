# frozen_string_literal: true

require 'pangea/resources/types'
require_relative 'video_codec_settings'

module Pangea
  module Resources
    module AWS
      module Types
        module MediaLiveChannel
            T = Resources::Types

          # H265 and MPEG2 codec type definitions

          module VideoCodecH265Mpeg2
            T = Resources::Types
            VCS = VideoCodecSettings

            # H265 color space settings
            Hdr10Settings = T::Hash.schema(
              max_cll?: T::Integer.optional,
              max_fall?: T::Integer.optional
            ).lax

            ColorSpaceSettings = T::Hash.schema(
              colorspace_passthrough_settings?: T::Hash.optional,
              dolby_vision81_settings?: T::Hash.optional,
              hdr10_settings?: Hdr10Settings.optional,
              rec601_settings?: T::Hash.optional,
              rec709_settings?: T::Hash.optional
            ).lax

            # H265 settings
            H265Settings = T::Hash.schema(
              adaptive_quantization?: T::String.constrained(included_in: ['AUTO', 'HIGH', 'HIGHER', 'LOW', 'MAX', 'MEDIUM', 'OFF']).optional,
              afd_signaling?: T::String.constrained(included_in: ['AUTO', 'FIXED', 'NONE']).optional,
              alternative_transfer_function?: T::String.constrained(included_in: ['INSERT', 'OMIT']).optional,
              bitrate?: T::Integer.optional,
              buf_size?: T::Integer.optional,
              color_metadata?: T::String.constrained(included_in: ['IGNORE', 'INSERT']).optional,
              color_space_settings?: ColorSpaceSettings.optional,
              filter_settings?: VCS::FilterSettings.optional,
              fixed_afd?: VCS::AfdValues.optional,
              flicker_aq?: T::String.constrained(included_in: ['DISABLED', 'ENABLED']).optional,
              framerate_control?: T::String.constrained(included_in: ['INITIALIZE_FROM_SOURCE', 'SPECIFIED']).optional,
              framerate_denominator?: T::Integer.optional,
              framerate_numerator?: T::Integer.optional,
              gop_closed_cadence?: T::Integer.optional,
              gop_size?: T::Float.optional,
              gop_size_units?: T::String.constrained(included_in: ['FRAMES', 'SECONDS']).optional,
              level?: T::String.constrained(included_in: ['H265_LEVEL_1', 'H265_LEVEL_2', 'H265_LEVEL_2_1', 'H265_LEVEL_3', 'H265_LEVEL_3_1', 'H265_LEVEL_4', 'H265_LEVEL_4_1', 'H265_LEVEL_5', 'H265_LEVEL_5_1', 'H265_LEVEL_5_2', 'H265_LEVEL_6', 'H265_LEVEL_6_1', 'H265_LEVEL_6_2', 'H265_LEVEL_AUTO']).optional,
              look_ahead_rate_control?: T::String.constrained(included_in: ['HIGH', 'LOW', 'MEDIUM']).optional,
              max_bitrate?: T::Integer.optional,
              min_i_interval?: T::Integer.optional,
              par_control?: T::String.constrained(included_in: ['INITIALIZE_FROM_SOURCE', 'SPECIFIED']).optional,
              par_denominator?: T::Integer.optional,
              par_numerator?: T::Integer.optional,
              profile?: T::String.constrained(included_in: ['MAIN', 'MAIN_10BIT']).optional,
              qvbr_quality_level?: T::Integer.optional,
              rate_control_mode?: T::String.constrained(included_in: ['CBR', 'MULTIPLEX', 'QVBR']).optional,
              scan_type?: T::String.constrained(included_in: ['INTERLACED', 'PROGRESSIVE']).optional,
              scene_change_detect?: T::String.constrained(included_in: ['DISABLED', 'ENABLED']).optional,
              slices?: T::Integer.optional,
              tier?: T::String.constrained(included_in: ['HIGH', 'MAIN']).optional,
              timecode_insertion?: T::String.constrained(included_in: ['DISABLED', 'PIC_TIMING_SEI']).optional,
              timecode_burnin_settings?: VCS::TimecodeBurninSettings.optional
            ).lax

            # MPEG2 settings
            Mpeg2Settings = T::Hash.schema(
              adaptive_quantization?: T::String.constrained(included_in: ['AUTO', 'HIGH', 'LOW', 'MEDIUM', 'OFF']).optional,
              afd_signaling?: T::String.constrained(included_in: ['AUTO', 'FIXED', 'NONE']).optional,
              color_metadata?: T::String.constrained(included_in: ['IGNORE', 'INSERT']).optional,
              color_space?: T::String.constrained(included_in: ['AUTO', 'PASSTHROUGH']).optional,
              display_aspect_ratio?: T::String.constrained(included_in: ['DISPLAYRATIO16X9', 'DISPLAYRATIO4X3']).optional,
              filter_settings?: VCS::FilterSettings.optional,
              fixed_afd?: VCS::AfdValues.optional,
              framerate_control?: T::String.constrained(included_in: ['INITIALIZE_FROM_SOURCE', 'SPECIFIED']).optional,
              framerate_denominator?: T::Integer.optional,
              framerate_numerator?: T::Integer.optional,
              gop_closed_cadence?: T::Integer.optional,
              gop_num_b_frames?: T::Integer.optional,
              gop_size?: T::Float.optional,
              gop_size_units?: T::String.constrained(included_in: ['FRAMES', 'SECONDS']).optional,
              scan_type?: T::String.constrained(included_in: ['INTERLACED', 'PROGRESSIVE']).optional,
              subgop_length?: T::String.constrained(included_in: ['DYNAMIC', 'FIXED']).optional,
              timecode_insertion?: T::String.constrained(included_in: ['DISABLED', 'GOP_TIMECODE']).optional,
              timecode_burnin_settings?: VCS::TimecodeBurninSettings.optional
            ).lax

            # Video codec settings container
            CodecSettings = T::Hash.schema(
              frame_capture_settings?: VCS::FrameCaptureSettings.optional,
              h264_settings?: VCS::H264Settings.optional,
              h265_settings?: H265Settings.optional,
              mpeg2_settings?: Mpeg2Settings.optional
            ).lax

            # Video description
            VideoDescription = T::Hash.schema(
              codec_settings?: CodecSettings.optional,
              height?: T::Integer.optional,
              name: T::String,
              respond_to_afd?: T::String.constrained(included_in: ['NONE', 'PASSTHROUGH', 'RESPOND']).optional,
              scaling_behavior?: T::String.constrained(included_in: ['DEFAULT', 'STRETCH_TO_OUTPUT']).optional,
              sharpness?: T::Integer.optional,
              width?: T::Integer.optional
            ).lax


          end
        end
      end
    end
  end
end
