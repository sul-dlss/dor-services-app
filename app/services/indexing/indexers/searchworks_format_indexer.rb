# frozen_string_literal: true

module Indexing
  module Indexers
    # Creates the Searchworks format field, used for the format facet.
    # For records that have a folio_id, we'll look for the marc data and use
    # this logic:
    # https://github.com/sul-dlss/searchworks_traject_indexer/blob/93e091eec3d195e92a3ec8229338c47cfe300475/lib/traject/config/folio_format_config.rb#L13
    # except we ignore any logic that depends on holdings.
    # Otherwise, if there is no hrid, we'll use this logic:
    # https://github.com/sul-dlss/searchworks_traject_indexer/blob/8994c9ee01d21ded323434ec0ac0407f8f18a310/lib/traject/config/sdr_config.rb#L209-L224
    class SearchworksFormatIndexer # rubocop:disable Metrics/ClassLength
      def self.value(cocina_display_record:)
        new(cocina_display_record:).value
      end

      def initialize(cocina_display_record:)
        @cocina_display_record = cocina_display_record
      end

      attr_reader :cocina_display_record

      def value
        if marc_record
          value_from_marc
        else
          cocina_display_record.searchworks_resource_types
        end
      end

      def value_from_marc
        @record = { 'format_hsim' => [] }
        add_folio_format_fields
        @record['format_hsim']
      end

      # This is copied verbatim from https://github.com/sul-dlss/searchworks_traject_indexer/blob/93e091eec3d195e92a3ec8229338c47cfe300475/lib/traject/config/folio_format_config.rb#L13
      # rubocop:disable Metrics/AbcSize
      # rubocop:disable Metrics/MethodLength
      def add_folio_format_fields # rubocop:disable Metrics/CyclomaticComplexity
        to_field 'format_hsim',
                 condition(
                   leader?(byte: 6, values: %w[p t d f]),
                   literal('Archive/Manuscript')
                 )

        to_field 'format_hsim',
                 all_conditions(
                   leader?(byte: 6, value: 'a'),
                   leader?(byte: 7, value: 'c'),
                   literal('Archive/Manuscript')
                 )

        to_field 'format_hsim',
                 condition(
                   marc_subfield_contains?('245', subfield: 'h', values: ['manuscript', 'manuscript/digital']),
                   literal('Archive/Manuscript')
                 )

        to_field 'format_hsim',
                 all_conditions(
                   leader?(byte: 6, values: %w[a t]),
                   leader?(byte: 7, values: %w[a m]),
                   literal('Book')
                 )

        to_field 'format_hsim',
                 all_conditions(
                   leader?(byte: 7, value: 's'),
                   control_field_byte?('008', byte: 21, value: 'm'),
                   literal('Book')
                 )

        to_field 'format_hsim',
                 all_conditions(
                   control_field_byte?('006', { byte: 0, value: 's' }, { byte: 4, value: 'm' }),
                   literal('Book')
                 )

        to_field 'format_hsim',
                 all_conditions(
                   leader?(byte: 7, values: %w[i s]),
                   control_field_byte?('008', byte: 21, value: 'd'),
                   literal('Database')
                 )

        to_field 'format_hsim',
                 all_conditions(
                   control_field_byte?('006', { byte: 0, value: 's' }, { byte: 4, value: 'd' }),
                   literal('Database')
                 )

        to_field 'format_hsim',
                 all_conditions(
                   leader?(byte: 6, value: 'm'),
                   control_field_byte?('008', byte: 26, value: 'j'),
                   literal('Database')
                 )

        # Statistical code is 'Database'
        # to_field 'format_hsim' do |record, accumulator, _context|
        #   accumulator << 'Database' if record.statistical_codes.any? { |stat_code| stat_code['name'] == 'Database' }
        # end

        to_field 'format_hsim',
                 all_conditions(
                   leader?(byte: 6, value: 'm'),
                   control_field_byte?('008', byte: 26, value: 'a'),
                   literal('Dataset')
                 )

        # to_field 'format_hsim' do |record, acc, _ctx|
        #   acc << 'Equipment' if record.respond_to?(:holdings) && record.holdings.any? do |h|
        #     h.dig('holdingsType', 'name') == 'Equipment'
        #   end
        # end

        to_field 'format_hsim',
                 all_conditions(
                   leader?(byte: 6, value: 'k'),
                   control_field_byte?('008', byte: 33, value: /[aciklnopst 0-9|]/),
                   literal('Image')
                 )

        to_field 'format_hsim',
                 all_conditions(
                   leader?(byte: 6, value: 'g'),
                   control_field_byte?('008', byte: 33, value: /[ aciklnopst]/),
                   literal('Image')
                 )

        image_terms = ['art original', 'digital graphic', 'slide', 'slides', 'chart', 'art reproduction', 'graphic',
                       'technical drawing', 'flash card', 'transparency', 'activity card', 'picture',
                       'graphic/digital graphic', 'diapositives']

        to_field 'format_hsim',
                 condition(
                   marc_subfield_contains?('245', subfield: 'h', values: image_terms),
                   literal('Image')
                 )

        to_field 'format_hsim',
                 all_conditions(
                   control_field_byte?('007', byte: 0, values: %w[k r]),
                   marc_subfield_contains?('245', subfield: 'h', value: 'kit'),
                   literal('Image')
                 )

        to_field 'format_hsim',
                 all_conditions(
                   control_field_byte?('007', { byte: 0, value: 'k' }, { byte: 1, values: %w[g h r v] }),
                   literal_multiple('Image', 'Image|Photo')
                 )

        to_field 'format_hsim',
                 all_conditions(
                   control_field_byte?('007', { byte: 0, value: 'k' }, { byte: 1, value: 'k' }),
                   literal_multiple('Image', 'Image|Poster')
                 )

        to_field 'format_hsim',
                 all_conditions(
                   control_field_byte?('007', { byte: 0, value: 'g' }, { byte: 1, value: 's' }),
                   literal_multiple('Image', 'Image|Slide')
                 )

        to_field 'format_hsim',
                 all_conditions(
                   leader?(byte: 7, value: 's'),
                   control_field_byte?('008', byte: 21, value: /[\\ gjpst|]/),
                   literal('Journal/Periodical')
                 )
        to_field 'format_hsim',
                 all_conditions(
                   control_field_byte?('006', { byte: 0, value: 's' }, { byte: 4, value: /[\\ gjpst|]/ }),
                   literal('Journal/Periodical')
                 )

        to_field 'format_hsim',
                 condition(
                   marc_subfield_contains?('590', subfield: 'a', value: 'MARCit brief record'),
                   literal('Journal/Periodical')
                 )

        to_field 'format_hsim',
                 all_conditions(
                   leader?(byte: 7, values: %w[s i]),
                   control_field_byte?('008', byte: 21, value: 'l'),
                   literal('Loose-leaf')
                 )

        to_field 'format_hsim',
                 all_conditions(
                   control_field_byte?('006', { byte: 0, value: 's' }, { byte: 4, value: 'l' }),
                   literal('Loose-leaf')
                 )

        to_field 'format_hsim',
                 condition(
                   leader?(byte: 6, values: %w[e f]),
                   literal('Map')
                 )

        to_field 'format_hsim',
                 all_conditions(
                   marc_subfield_contains?('245', subfield: 'h', value: 'kit'),
                   control_field_byte?('007', byte: 0, values: %w[a d]),
                   literal('Map')
                 )

        to_field 'format_hsim',
                 condition(
                   control_field_byte?('007', byte: 0, value: 'd'),
                   literal_multiple('Map', 'Map|Globe')
                 )

        to_field 'format_hsim',
                 condition(
                   control_field_byte?('007', byte: 0, value: 'r'),
                   literal_multiple('Map', 'Map|Remote-sensing image')
                 )

        to_field 'format_hsim',
                 condition(
                   control_field_byte?('007', byte: 0, value: 'r'),
                   literal_multiple('Map', 'Map|Remote-sensing image')
                 )

        to_field 'format_hsim',
                 condition(
                   control_field_byte?('007', byte: 0, value: 'h'),
                   literal_multiple('Microform')
                 )

        to_field 'format_hsim',
                 all_conditions(
                   marc_subfield_contains?('245', subfield: 'h', value: 'microform'),
                   literal('Microform')
                 )

        to_field 'format_hsim',
                 condition(
                   leader?(byte: 6, values: %w[c d]),
                   literal('Music score')
                 )

        to_field 'format_hsim',
                 all_conditions(
                   marc_subfield_contains?('245', subfield: 'h', value: 'kit'),
                   control_field_byte?('007', byte: 0, value: 'q'),
                   literal('Music score')
                 )

        to_field 'format_hsim',
                 all_conditions(
                   leader?(byte: 7, value: 's'),
                   control_field_byte?('008', byte: 21, value: 'n'),
                   literal('Newspaper')
                 )

        to_field 'format_hsim',
                 all_conditions(
                   control_field_byte?('006', { byte: 0, value: 's' }, { byte: 4, value: 'n' }),
                   literal('Newspaper')
                 )

        to_field 'format_hsim',
                 all_conditions(
                   leader?(byte: 6, value: 'r'),
                   literal('Object')
                 )

        # This condition contains negative logic to exclude certain values.
        # This pattern differs from the custom macros we wrote for other blocks, so it is written out longhand.
        to_field 'format_hsim' do |record, accumulator, _context|
          leader = record.leader
          next unless leader && leader.length > 6 && leader[6] == 'm'

          field008 = record['008']
          excluded_values = %w[a g j]
          byte26 = field008.value[26] if field008
          accumulator << 'Software/Multimedia' if field008.nil? || byte26.nil? || !excluded_values.include?(byte26) # rubocop:disable Rails/NegateInclude
        end

        to_field 'format_hsim',
                 all_conditions(
                   marc_subfield_contains?('245', subfield: 'h', value: 'kit'),
                   control_field_byte?('007', byte: 0, value: 'c'),
                   literal('Software/Multimedia')
                 )

        to_field 'format_hsim',
                 condition(
                   leader?(byte: 6, values: %w[i j]),
                   literal('Sound recording')
                 )

        to_field 'format_hsim',
                 condition(
                   control_field_byte?('006', byte: 0, values: %w[i j]),
                   literal('Sound recording')
                 )

        to_field 'format_hsim',
                 condition(
                   marc_subfield_contains?('245', subfield: 'h', value: 'sound recording'),
                   literal('Sound recording')
                 )

        to_field 'format_hsim',
                 all_conditions(
                   control_field_byte?('007', { byte: 0, value: 's' }, { byte: 3, value: 'b' }),
                   literal_multiple('Sound recording', 'Sound recording|Vinyl disc') # 33 rpm disc (vinyl LP)')
                 )

        to_field 'format_hsim',
                 all_conditions(
                   control_field_byte?('007', { byte: 0, value: 's' }, { byte: 3, value: 'c' }),
                   literal_multiple('Sound recording', 'Sound recording|Vinyl disc') # 45 rpm disc (vinyl)')
                 )

        to_field 'format_hsim',
                 all_conditions(
                   control_field_byte?('007', { byte: 0, value: 's' }, { byte: 3, value: 'd' }),
                   literal_multiple('Sound recording', 'Sound recording|78 rpm disc (shellac)')
                 )

        to_field 'format_hsim',
                 all_conditions(
                   control_field_byte?('007', { byte: 0, value: 's' }, { byte: 6, value: 'j' }),
                   literal_multiple('Sound recording', 'Sound recording|Audiocassette')
                 )

        to_field 'format_hsim',
                 all_conditions(
                   control_field_byte?('007', { byte: 0, value: 's' }, { byte: 3, value: 'f' }),
                   literal_multiple('Sound recording', 'Sound recording|CD')
                 )
        piano_roll_terms = ['piano roll', 'organ roll', 'audio roll']

        to_field 'format_hsim',
                 condition(
                   marc_subfield_contains?('338', subfield: 'a', values: piano_roll_terms),
                   literal_multiple('Sound recording', 'Sound recording|Piano/Organ roll')
                 )

        to_field 'format_hsim',
                 condition(
                   marc_subfield_contains?('300', subfield: 'a', values: piano_roll_terms),
                   literal_multiple('Sound recording', 'Sound recording|Piano/Organ roll')
                 )

        to_field 'format_hsim',
                 all_conditions(
                   leader?(byte: 6, value: 'g'),
                   control_field_byte?('006', byte: 4, value: /[ |fmv0-9]/),
                   literal('Video/Film')
                 )
        video_terms = ['videorecording', 'video recording', 'videorecordings', 'video recordings', 'motion picture',
                       'filmstrip', 'videodisc', 'videocassette']

        to_field 'format_hsim',
                 condition(
                   marc_subfield_contains?('245', subfield: 'n', values: video_terms),
                   literal(
                     'Video/Film'
                   )
                 )

        to_field 'format_hsim',
                 all_conditions(
                   marc_subfield_contains?('245', subfield: 'h', value: 'kit'),
                   control_field_byte?('007', byte: 0, values: %w[g m v]),
                   literal('Video/Film')
                 )

        # TODO: Video/Film|Online video

        to_field 'format_hsim',
                 all_conditions(
                   control_field_byte?('007', { byte: 0, value: 'v' }, { byte: 4, value: 's' }),
                   literal_multiple('Video/Film', 'Video/Film|Blu-ray')
                 )

        blu_ray_terms = ['Bluray', 'Blu-ray', 'Blu ray']

        to_field 'format_hsim',
                 condition(
                   marc_subfield_contains?('538', subfield: 'a', values: blu_ray_terms),
                   literal_multiple('Video/Film', 'Video/Film|Blu-ray')
                 )

        # to_field 'format_hsim' do |record, acc, _ctx|
        #   if record.holdings.any? { |h| h['callNumber']&.include?('BLU-RAY') }
        #     acc << 'Video/Film'
        #     acc << 'Video/Film|Blu-ray'
        #   end
        # end

        to_field 'format_hsim',
                 all_conditions(
                   control_field_byte?('007', { byte: 0, value: 'v' }, { byte: 4, value: 'v' }),
                   literal_multiple('Video/Film', 'Video/Film|DVD')
                 )

        to_field 'format_hsim',
                 condition(
                   marc_subfield_contains?('538', subfield: 'a', value: 'DVD'),
                   literal_multiple('Video/Film', 'Video/Film|DVD')
                 )

        to_field 'format_hsim',
                 all_conditions(
                   control_field_byte?('007', { byte: 0, value: 'v' }, { byte: 4, value: 'g' }),
                   literal_multiple('Video/Film', 'Video/Film|DVD') # Laser disc
                 )

        to_field 'format_hsim',
                 all_conditions(
                   control_field_byte?('007', { byte: 0, value: 'v' }, { byte: 4, values: %w[a i j] }),
                   literal_multiple('Video/Film', 'Video/Film|Videocassette') # Beta
                 )

        to_field 'format_hsim',
                 all_conditions(
                   control_field_byte?('007', { byte: 0, value: 'v' }, { byte: 4, value: 'b' }),
                   literal_multiple('Video/Film', 'Video/Film|Videocassette') # VHS
                 )

        to_field 'format_hsim',
                 condition(
                   marc_subfield_contains?('538', subfield: 'a', value: 'VHS'),
                   literal_multiple('Video/Film', 'Video/Film|Videocassette') # VHS
                 )

        to_field 'format_hsim',
                 all_conditions(
                   control_field_byte?('007', { byte: 0, value: 'v' }, { byte: 4, value: 'q' }),
                   literal_multiple('Video/Film', 'Video/Film|Videocassette') # Hi-8 mm
                 )

        to_field 'format_hsim',
                 condition(
                   control_field_byte?('007', byte: 0, value: 'm'),
                   literal_multiple('Video/Film', 'Video/Film|Film reel')
                 )

        to_field 'format_hsim',
                 all_conditions(
                   marc_subfield_contains?('655', subfield: 'a', value: 'Video game'),
                   literal('Video game')
                 )

        to_field 'format_hsim',
                 all_conditions(
                   leader?(byte: 6, value: 'm'),
                   control_field_byte?('008', byte: 26, value: 'g'),
                   literal('Video game')
                 )

        to_field 'format_hsim',
                 all_conditions(
                   leader?(byte: 7, value: 's'),
                   control_field_byte?('008', byte: 21, values: %w[h w]),
                   literal('Website')
                 )

        to_field 'format_hsim',
                 all_conditions(
                   control_field_byte?('006', { byte: 0, value: 's' }, { byte: 4, values: %w[h w] }),
                   literal('Website')
                 )

        # TODO: Website|Archived website
      end
      # rubocop:enable Metrics/AbcSize
      # rubocop:enable Metrics/MethodLength

      def marc_record
        @marc_record ||= MarcCacheEntry.find_by(folio_hrid:)&.marc if folio_hrid
      end

      # These methods mimic the Traject API
      def to_field(field_name, value = nil)
        if block_given?
          # debugger
          yield marc_record, @record[field_name]
        elsif value
          Array(value).each { @record[field_name] << it }
        end
      end

      def leader?(byte:, value: nil, values: nil)
        value_at_byte = marc_record&.leader&.[](byte)

        if value
          value_at_byte == value
        elsif values
          values.include?(value_at_byte)
        end
      end

      def literal(value)
        value
      end

      def literal_multiple(*values)
        values
      end

      def condition(test, value)
        value if test
      end

      def all_conditions(*tests, value)
        value if tests.all?
      end

      def marc_subfield_contains?(tag, subfield:, values: nil, value: nil) # rubocop:disable Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity
        values ||= [value]
        field = marc_record&.fields&.find { |field| field.tag == tag }
        field&.subfields&.any? do |sf|
          sf.code == subfield && values.any? { sf.value.downcase.include?(it.downcase) }
        end
      end

      def control_field_byte?(tag, *filters) # rubocop:disable Metrics/AbcSize,Metrics/CyclomaticComplexity
        field = marc_record.fields&.find { |field| field.tag == tag }
        return false unless field

        filters.all? do |filter|
          value_at_byte = field.value.[](filter[:byte])
          case filter[:value]
          when String
            value_at_byte == filter[:value]
          when Regexp
            filter[:value].match? value_at_byte
          else
            filter[:values]&.any?(value_at_byte)
          end
        end
      end

      delegate :folio_hrid, to: :cocina_display_record
    end
  end
end
