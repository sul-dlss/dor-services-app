# frozen_string_literal: true

require 'rails_helper'

RSpec.describe EventsMigrationService do
  let(:druid) { 'druid:bc718vt5637' }

  let(:fedora_object) { Dor::Item.new(pid: druid) }

  let(:version_created) { Time.zone.parse('2012-03-29T17:23:02Z') }

  describe '#migrate' do
    let(:events_xml) do
      <<~XML
        <events>
          <event type="remediation" who="Dor::Identifiable 3.6.1" when="2016-03-09T04:55:24Z">Record Remediation Version</event>
          <event type="open" who="blalbrit" when="2016-05-27T17:52:30Z">Version 2 opened</event>
          <event type="close" who="Robert J Rohrbacher" when="2016-05-31T22:25:03Z">Version 2 closed</event>
          <event type="remediation" who="Dor::Identifiable 3.6.1" when="2016-05-31T22:36:22Z">Record Remediation Version</event>
          <event type="remediation" who="Dor::Identifiable 3.6.1" when="2016-10-07T00:11:42Z">Record Remediation Version</event>
          <event type="open" who="Meagan K Trott" when="2017-03-29T17:23:02Z">Version 4 opened</event>
          <event type="close" who="Benjamin L Albritton" when="2017-05-22T17:27:59Z">Version 4 closed</event>
        </events>
      XML
    end

    context 'when version metadata' do
      before do
        fedora_object.events.content = events_xml
        Event.create!(druid: druid, created_at: version_created, event_type: 'version_open', data: { version: '2' })
        Event.create!(druid: druid, created_at: version_created, event_type: 'version_close', data: { version: '4' })
      end

      it 'creates events' do
        described_class.migrate(fedora_object)

        open_events = Event.where(event_type: 'version_open')
        expect(open_events.size).to eq(2)
        # This demonstrates that existing events are ignored.
        expect(open_events.first.created_at).to eq(version_created)

        # This is a new event
        open_event = open_events.last
        expect(open_event.created_at).to eq(Time.zone.parse('2017-03-29T17:23:02Z'))
        expect(open_event.data).to eq({ who: 'Meagan K Trott', version: '4' }.with_indifferent_access)

        close_events = Event.where(event_type: 'version_close')
        expect(close_events.size).to eq(2)
        # This demonstrates that existing events are ignored.
        expect(close_events.first.created_at).to eq(version_created)

        # This is a new event
        close_event = close_events.last
        expect(close_event.created_at).to eq(Time.zone.parse('2016-05-31T22:25:03Z'))
        expect(close_event.data).to eq({ who: 'Robert J Rohrbacher', version: '2' }.with_indifferent_access)
      end
    end
  end
end
