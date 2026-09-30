# frozen_string_literal: true

module Indexing
  module Indexers
    # Indexes the rights metadata
    class RightsMetadataIndexer
      # This should be kept in sync with https://github.com/sul-dlss/argo-b3/blob/main/app/services/constants.rb
      LICENSES = {
        'https://cocina.sul.stanford.edu/licenses/none' => { # Only used in some legacy ETDs.
          code: 'none',
          label: 'None'
        },
        'https://creativecommons.org/licenses/by/3.0/legalcode' => {
          code: 'CC BY 3.0',
          label: 'CC BY 3.0 Attribution Unported'
        },
        'https://creativecommons.org/licenses/by-sa/3.0/legalcode' => {
          code: 'CC BY-SA 3.0',
          label: 'CC BY-SA 3.0 Attribution-ShareAlike Unported'
        },
        'https://creativecommons.org/licenses/by-nd/3.0/legalcode' => {
          code: 'CC BY-ND 3.0',
          label: 'CC BY-ND 3.0 Attribution-NoDerivatives Unported'
        },
        'https://creativecommons.org/licenses/by-nc/3.0/legalcode' => {
          code: 'CC BY-NC 3.0',
          label: 'CC BY-NC 3.0 Attribution-NonCommercial Unported'
        },
        'https://creativecommons.org/licenses/by-nc-sa/3.0/legalcode' => {
          code: 'CC BY-NC-SA 3.0',
          label: 'CC BY-NC-SA 3.0 Attribution-NonCommercial-ShareAlike Unported'
        },
        'https://creativecommons.org/licenses/by-nc-nd/3.0/legalcode' => {
          code: 'CC BY-NC-ND 3.0',
          label: 'CC BY-NC-ND 3.0 Attribution-NonCommercial-NoDerivatives Unported'
        },
        'https://creativecommons.org/licenses/by/4.0/legalcode' => {
          code: 'CC BY 4.0',
          label: 'CC BY 4.0 Attribution International'
        },
        'https://creativecommons.org/licenses/by-sa/4.0/legalcode' => {
          code: 'CC BY-SA 4.0',
          label: 'CC BY-SA 4.0 Attribution-ShareAlike International'
        },
        'https://creativecommons.org/licenses/by-nd/4.0/legalcode' => {
          code: 'CC BY-ND 4.0',
          label: 'CC BY-ND 4.0 Attribution-NoDerivatives International'
        },
        'https://creativecommons.org/licenses/by-nc/4.0/legalcode' => {
          code: 'CC BY-NC 4.0',
          label: 'CC BY-NC 4.0 Attribution-NonCommercial International'
        },
        'https://creativecommons.org/licenses/by-nc-sa/4.0/legalcode' => {
          code: 'CC BY-NC-SA 4.0',
          label: 'CC BY-NC-SA 4.0 Attribution-NonCommercial-ShareAlike International'
        },
        'https://creativecommons.org/licenses/by-nc-nd/4.0/legalcode' => {
          code: 'CC BY-NC-ND 4.0',
          label: 'CC BY-NC-ND 4.0 Attribution-NonCommercial-NoDerivatives International'
        },
        'https://creativecommons.org/publicdomain/zero/1.0/legalcode' => {
          code: 'CC0-1.0',
          label: 'CC0 1.0 Universal'
        },
        'https://creativecommons.org/publicdomain/mark/1.0/' => {
          code: 'PDM',
          label: 'Public Domain Mark 1.0'
        },
        'https://opendatacommons.org/licenses/pddl/1-0/' => {
          code: 'PDDL-1.0',
          label: 'Open Data Commons Public Domain Dedication and License 1.0'
        },
        'https://opendatacommons.org/licenses/by/1-0/' => {
          code: 'ODC-By-1.0',
          label: 'Open Data Commons Attribution License 1.0'
        },
        'https://opendatacommons.org/licenses/odbl/1-0/' => {
          code: 'ODbL-1.0',
          label: 'Open Data Commons Open Database License 1.0'
        },
        'https://www.gnu.org/licenses/agpl.txt' => {
          code: 'AGPL-3.0-only',
          label: 'AGPL-3.0-only GNU Affero General Public License'
        },
        'https://www.apache.org/licenses/LICENSE-2.0' => {
          code: 'Apache-2.0',
          label: 'Apache-2.0'
        },
        'https://opensource.org/licenses/BSD-2-Clause' => {
          code: 'BSD-2-Clause',
          label: "BSD-2-Clause 'Simplified' License"
        },
        'https://opensource.org/licenses/BSD-3-Clause' => {
          code: 'BSD-3-Clause',
          label: "BSD-3-Clause 'New' or 'Revised' License"
        },
        'https://opensource.org/licenses/cddl1' => {
          code: 'CDDL-1.1',
          label: 'CDDL-1.1 Common Development and Distribution License'
        },
        'https://www.eclipse.org/legal/epl-2.0' => {
          code: 'EPL-2.0',
          label: 'EPL-2.0 Eclipse Public License'
        },
        'https://www.gnu.org/licenses/gpl-3.0-standalone.html' => {
          code: 'GPL-3.0-only',
          label: 'GPL-3.0-only GNU General Public License'
        },
        'https://www.isc.org/downloads/software-support-policy/isc-license/' => {
          code: 'ISC',
          label: 'ISC License'
        },
        'https://www.gnu.org/licenses/lgpl-3.0-standalone.html' => {
          code: 'LGPL-3.0-only',
          label: 'LGPL-3.0-only Lesser GNU Public License'
        },
        'https://opensource.org/licenses/MIT' => {
          code: 'MIT',
          label: 'MIT License'
        },
        'https://www.mozilla.org/MPL/2.0/' => {
          code: 'MPL-2.0',
          label: 'MPL-2.0 Mozilla Public License'
        }
      }.freeze

      attr_reader :cocina

      def initialize(cocina:, **)
        @cocina = cocina
      end

      # @return [Hash] the partial solr document for rightsMetadata
      def to_solr
        {
          'copyright_ssim' => cocina.access.copyright,
          'use_statement_ssim' => cocina.access.useAndReproductionStatement,
          'use_license_machine_ssidv' => license_value(:code),
          'use_license_label_uri_ssidv' => license_label_uri,
          'use_license_label_ss' => license_value(:label),
          'use_license_uri_ssidv' => license_uri,
          'rights_descriptions_ssimdv' => rights_description
        }.compact
      end

      private

      def rights_description
        return Indexing::Builders::CollectionRightsDescriptionBuilder.build(cocina) if cocina.collection?

        Cocina::Models::Builders::DroRightsDescriptionBuilder.build(cocina)
      end

      # @return [String] the composite "<label>:<uri>" value for faceting
      def license_label_uri
        return unless license_uri

        Indexing::CompositeFacetValue.build(label: license_value(:label), id: license_uri)
      end

      # @param key [Symbol] :code or :label
      # @return [String] the value if we've defined one, or the URI if we haven't.
      def license_value(key)
        return unless license_uri

        LICENSES.dig(license_uri, key) || license_uri
      end

      def license_uri
        cocina.access.license
      end
    end
  end
end
