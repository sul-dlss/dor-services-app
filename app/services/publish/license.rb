# frozen_string_literal: true

module Publish
  # This is the license entity used for translating a license URL into text on
  # to be added to the public descriptive metadata
  #
  # NOTE: be aware that mods_display parses the value of this node with a regex
  # See: https://github.com/sul-dlss/mods_display/blob/36e5bf7247fd7aa7892247af48033afaee2fd76b/lib/mods_display/fields/access_condition.rb#L79
  #
  class License
    attr_reader :description, :uri

    # Raised when the license provided is not valid
    class LegacyLicenseError < StandardError; end

    def initialize(url:)
      raise LegacyLicenseError unless LICENSES.key?(url)

      attrs = LICENSES.fetch(url)
      @uri = url
      @description = attrs.fetch(:label)
    end

    LICENSES = {
      'https://www.gnu.org/licenses/agpl.txt' => {
        label: 'AGPL-3.0-only GNU Affero General Public License'
      },
      'http://www.apache.org/licenses/LICENSE-2.0' => {
        label: 'Apache-2.0'
      },
      'https://opensource.org/licenses/BSD-2-Clause' => {
        label: 'BSD-2-Clause "Simplified" License'
      },
      'https://opensource.org/licenses/BSD-3-Clause' => {
        label: 'BSD-3-Clause "New" or "Revised" License'
      },
      'https://creativecommons.org/licenses/by/4.0/legalcode' => {
        label: 'CC BY: Attribution International'
      },
      'https://creativecommons.org/licenses/by-nc/4.0/legalcode' => {
        label: 'CC BY-NC: Attribution-NonCommercial International'
      },
      'https://creativecommons.org/licenses/by-nc-nd/4.0/legalcode' => {
        label: 'CC BY-NC-ND: Attribution-NonCommercial-No Derivatives'
      },
      'https://creativecommons.org/licenses/by-nc-sa/4.0/legalcode' => {
        label: 'CC BY-NC-SA: Attribution-NonCommercial-Share Alike International'
      },
      'https://creativecommons.org/licenses/by-nd/4.0/legalcode' => {
        label: 'CC BY-ND: Attribution-No Derivatives International'
      },
      'https://creativecommons.org/licenses/by-sa/4.0/legalcode' => {
        label: 'CC BY-SA: Attribution-Share Alike International'
      },
      'https://creativecommons.org/publicdomain/zero/1.0/legalcode' => {
        label: 'CC0 - 1.0'
      },
      'https://opensource.org/licenses/cddl1' => {
        label: 'CDDL-1.1 Common Development and Distribution License'
      },
      'https://www.eclipse.org/legal/epl-2.0' => {
        label: 'EPL-2.0 Eclipse Public License'
      },
      'https://www.gnu.org/licenses/gpl-3.0-standalone.html' => {
        label: 'GPL-3.0-only GNU General Public License'
      },
      'https://www.isc.org/downloads/software-support-policy/isc-license/' => {
        label: 'ISC License'
      },
      'https://www.gnu.org/licenses/lgpl-3.0-standalone.html' => {
        label: 'LGPL-3.0-only Lesser GNU Public License'
      },
      'https://opensource.org/licenses/MIT' => {
        label: 'MIT License'
      },
      'http://www.mozilla.org/MPL/2.0/' => {
        label: 'MPL-2.0 Mozilla Public License'
      },
      'https://opendatacommons.org/licenses/by/1-0/' => {
        label: 'ODC odc-by: ODC-By-1.0 Attribution License'
      },
      'http://opendatacommons.org/licenses/odbl/1.0/' => {
        # This is a non-canonical url found in some existing data. It redirects to
        # https://opendatacommons.org/licenses/odbl/1-0/
        label: 'ODC odbl: ODbL-1.0 Open Database License'
      },
      'https://opendatacommons.org/licenses/odbl/1-0/' => {
        label: 'ODC odbl: ODbL-1.0 Open Database License'
      },
      'https://creativecommons.org/publicdomain/mark/1.0/' => {
        label: 'CC pdm: Creative Commons Public Domain Mark 1.0'
      },
      'https://opendatacommons.org/licenses/pddl/1-0/' => {
        label: 'ODC pddl: Open Data Commons Public Domain Dedication and License (PDDL-1.0)'
      },
      'https://creativecommons.org/licenses/by/3.0/legalcode' => {
        label: 'CC by: Attribution 3.0 Unported License'
      },
      'https://creativecommons.org/licenses/by-sa/3.0/legalcode' => {
        label: 'CC by-sa: Attribution Share Alike 3.0 Unported License'
      },
      'https://creativecommons.org/licenses/by-nd/3.0/legalcode' => {
        label: 'CC by-nd: Attribution No Derivatives 3.0 Unported License'
      },
      'https://creativecommons.org/licenses/by-nc/3.0/legalcode' => {
        label: 'CC by-nc: Attribution-NonCommercial 3.0 Unported License'
      },
      'https://creativecommons.org/licenses/by-nc-sa/3.0/legalcode' => {
        label: 'CC by-nc-sa: Attribution-NonCommercial-Share Alike 3.0 Unported License'
      },
      'https://creativecommons.org/licenses/by-nc-nd/3.0/legalcode' => {
        label: 'CC by-nc-nd: Attribution-NonCommercial-No Derivative Works 3.0 Unported License'
      }
    }.freeze
  end
end
