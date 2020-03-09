# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RegistrationService do
  let(:pid) { 'druid:ab123cd4567' }
  let(:mock_repo) { instance_double(Rubydora::Repository) }
  let(:apo) { instantiate_fixture('druid:fg890hi1234', Dor::AdminPolicyObject) }

  before do
    allow(apo).to receive(:new_record?).and_return false
    allow(Dor).to receive(:find).with('druid:fg890hi1234').and_return(apo)
    allow(EventFactory).to receive(:create)
    stub_request(:post, 'https://dor-indexing-app.server/reindex/druid:ab123cd4567')
  end

  describe '#register_object' do
    subject(:register) { described_class.send(:register_object, request) }

    before do
      allow(Dor::SuriService).to receive(:mint_id).and_return(pid)
      allow(Dor::SearchService).to receive(:query_by_id).and_return([])
      allow(ActiveFedora::Base).to receive(:connection_for_pid).and_return(mock_repo)
      allow_any_instance_of(Dor::Collection).to receive(:save).and_return(true)
      allow_any_instance_of(Dor::Item).to receive(:create).and_return(true)
    end

    let(:params) do
      {
        object_type: 'item',
        content_model: 'googleScannedBook',
        admin_policy: 'druid:fg890hi1234',
        metadata_source: 'label',
        label: 'Google : Scanned Book 12345',
        source_id: { barcode: 9_191_919_191 },
        other_ids: { catkey: '000', uuid: '111' },
        tags: ['Google : Google Tag!', 'Google : Other Google Tag!']
      }
    end

    let(:request) { RegistrationRequest.new(params) }

    let(:mock_collection) do
      coll = Dor::Collection.new
      allow(coll).to receive(:new?).and_return false
      allow(coll).to receive(:new_record?).and_return false
      allow(coll).to receive(:pid).and_return 'druid:something'
      allow(coll).to receive(:save)
      coll
    end
    let(:world_xml) do
      <<-XML
        <?xml version="1.0"?>
        <rightsMetadata>
          <copyright>
            <human type="copyright">This work is in the Public Domain.</human>
          </copyright>
          <access type="discover">
            <machine>
              <world/>
            </machine>
          </access>
          <access type="read">
            <machine>
              <world/>
            </machine>
          </access>
          <use>
            <human type="creativecommons">Attribution Share Alike license</human>
            <machine type="creativecommons">by-sa</machine>
          </use>
        </rightsMetadata>
      XML
    end
    let(:stanford_xml) do
      <<-XML
        <?xml version="1.0"?>
        <rightsMetadata>
          <copyright>
            <human type="copyright">This work is in the Public Domain.</human>
          </copyright>
          <access type="discover">
            <machine>
              <world/>
            </machine>
          </access>
          <access type="read">
            <machine>
              <group>stanford</group>
            </machine>
          </access>
          <use>
            <human type="creativecommons">Attribution Share Alike license</human>
            <machine type="creativecommons">by-sa</machine>
          </use>
        </rightsMetadata>
      XML
    end
    let(:stanford_no_download_xml) do
      <<-XML
        <?xml version="1.0"?>
        <rightsMetadata>
          <copyright>
            <human type="copyright">This work is in the Public Domain.</human>
          </copyright>
          <access type="discover">
            <machine>
              <world/>
            </machine>
          </access>
          <access type="read">
            <machine>
              <group rule="no-download">stanford</group>
            </machine>
          </access>
          <use>
            <human type="creativecommons">Attribution Share Alike license</human>
            <machine type="creativecommons">by-sa</machine>
          </use>
        </rightsMetadata>
      XML
    end
    let(:location_music_xml) do
      <<-XML
        <?xml version="1.0"?>
        <rightsMetadata>
          <copyright>
            <human type="copyright">This work is in the Public Domain.</human>
          </copyright>
          <access type="discover">
            <machine>
              <world/>
            </machine>
          </access>
          <access type="read">
            <machine>
              <location>music</location>
            </machine>
          </access>
          <use>
            <human type="creativecommons">Attribution Share Alike license</human>
            <machine type="creativecommons">by-sa</machine>
          </use>
        </rightsMetadata>
      XML
    end

    context 'exception should be raised for' do
      it 'registering a duplicate PID' do
        params[:pid] = pid
        expect(Dor::SearchService).to receive(:query_by_id).with('druid:ab123cd4567').and_return([pid])
        expect { register }.to raise_error(Dor::DuplicateIdError)
      end

      it 'registering a duplicate source ID' do
        expect(Dor::SearchService).to receive(:query_by_id).with('barcode:9191919191').and_return([pid])
        expect { register }.to raise_error(Dor::DuplicateIdError)
      end

      it 'missing a required parameter' do
        params.delete(:object_type)
        expect { register }.to raise_error(Dor::ParameterError)
      end

      context 'when seed_datastream is present and something other than descMetadata' do
        it 'raises an error' do
          params[:seed_datastream] = ['invalid']
          expect { register }.to raise_error(Dor::ParameterError)
        end
      end

      context 'when the metadata_source is label and there is an empty label' do
        before do
          params[:label] = ''
        end

        it 'raises an error' do
          params[:metadata_source] = 'label'
          expect { register }.to raise_error(Dor::ParameterError)
        end
      end
    end

    RSpec.shared_examples 'common registration' do
      it 'produces a registered object' do
        expect(@obj.identityMetadata.otherId).to match_array(params[:other_ids].collect { |*e| e.join(':') })
      end
    end

    describe 'should set rightsMetadata based on the APO default (but replace read rights) even if it is a collection' do
      before do
        coll = Dor::Collection.new(pid: pid)
        allow(Dor::Collection).to receive(:new).and_return(coll)
        params[:rights] = 'stanford'
        params[:object_type] = 'collection'
        @obj = register
      end

      it_behaves_like 'common registration'
      it 'produces rightsMetadata XML' do
        expect(@obj.datastreams['rightsMetadata'].ng_xml).to be_equivalent_to stanford_xml
      end
    end

    context 'when seed_datastream is provided' do
      before do
        params[:seed_datastream] = ['descMetadata']
        params[:metadata_source] = nil
        allow(RefreshMetadataAction).to receive(:run)
      end

      it 'creates the datastream' do
        register
        expect(RefreshMetadataAction).to have_received(:run)
          .with(identifiers: ['catkey:000', 'uuid:111'], datastream: Dor::DescMetadataDS)
      end
    end

    context 'common cases' do
      before do
        expect_any_instance_of(Dor::Item).to receive(:save).and_return(true)
      end

      describe 'object registration' do
        before do
          @obj = register
        end

        it_behaves_like 'common registration'
        it 'produces isGovernedBy and hasModel assertions' do
          expect(@obj.rels_ext.to_rels_ext).to be_equivalent_to <<-XML
            <rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" xmlns:fedora="info:fedora/fedora-system:def/relations-external#"
              xmlns:fedora-model="info:fedora/fedora-system:def/model#" xmlns:hydra="http://projecthydra.org/ns/relations#">
              <rdf:Description rdf:about="info:fedora/druid:ab123cd4567">
                <hydra:isGovernedBy rdf:resource="info:fedora/druid:fg890hi1234"/>
                <fedora-model:hasModel rdf:resource="info:fedora/afmodel:Dor_Item"/>
                <fedora-model:hasModel rdf:resource='info:fedora/afmodel:Dor_Abstract' />
              </rdf:Description>
            </rdf:RDF>
          XML
        end
      end

      describe 'collection registration' do
        before do
          params[:collection] = 'druid:something'
          expect(Dor::Collection).to receive(:find).with('druid:something').and_return(mock_collection)
          @obj = register
        end

        it_behaves_like 'common registration'
        it 'produces correct RELS-EXT' do
          expect(@obj.datastreams['RELS-EXT'].to_rels_ext).to be_equivalent_to <<-XML
            <rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" xmlns:fedora="info:fedora/fedora-system:def/relations-external#"
              xmlns:fedora-model="info:fedora/fedora-system:def/model#" xmlns:hydra="http://projecthydra.org/ns/relations#">
              <rdf:Description rdf:about="info:fedora/druid:ab123cd4567">
                <hydra:isGovernedBy rdf:resource="info:fedora/druid:fg890hi1234"/>
                <fedora-model:hasModel rdf:resource="info:fedora/afmodel:Dor_Item"/>
                <fedora-model:hasModel rdf:resource='info:fedora/afmodel:Dor_Abstract' />
                <fedora:isMemberOf rdf:resource="info:fedora/druid:something"/>
                <fedora:isMemberOfCollection rdf:resource="info:fedora/druid:something"/>
              </rdf:Description>
            </rdf:RDF>
          XML
        end
      end

      context 'when passed rights=' do
        describe 'default' do
          before do
            params[:rights] = 'default'
            @obj = register
          end

          it_behaves_like 'common registration'
          it 'sets rightsMetadata based on the APO default' do
            expect(@obj.datastreams['rightsMetadata'].ng_xml).to be_equivalent_to stanford_xml
          end
        end

        describe 'world' do
          before do
            params[:rights] = 'world'
            @obj = register
          end

          it_behaves_like 'common registration'
          it 'sets rightsMetadata based on the APO default but replace read rights to be world' do
            expect(@obj.datastreams['rightsMetadata'].ng_xml).to be_equivalent_to world_xml
          end
        end

        describe 'loc:music' do
          before do
            params[:rights] = 'loc:music'
            @obj = register
          end

          it_behaves_like 'common registration'
          it 'sets rightsMetadata based on the APO default but replace read rights to be loc:music' do
            expect(@obj.datastreams['rightsMetadata'].ng_xml).to be_equivalent_to location_music_xml
          end
        end

        describe 'stanford no-download' do
          before do
            params[:rights] = 'stanford-nd'
            @obj = register
          end

          it_behaves_like 'common registration'
          it 'sets rightsMetadata based on the APO default but replace read rights to be group stanford with the no-download rule' do
            expect(@obj.datastreams['rightsMetadata'].ng_xml).to be_equivalent_to stanford_no_download_xml
          end
        end
      end

      context 'when passed metadata_source=label' do
        before do
          params[:metadata_source] = 'label'
          params[:abstract] = 'A very fine description indeed.'
          @obj = register
        end

        it_behaves_like 'common registration'

        it 'sets the descriptive metadata to basic mods using the label as title' do
          expect(@obj.datastreams['descMetadata'].ng_xml).to be_equivalent_to <<-XML
            <?xml version="1.0"?>
            <mods xmlns="http://www.loc.gov/mods/v3" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" version="3.6" xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
               <titleInfo>
                  <title>Google : Scanned Book 12345</title>
               </titleInfo>
               <abstract>A very fine description indeed.</abstract>
            </mods>
          XML
        end
      end

      it 'truncates label if >= 255 chars' do
        # expect(Dor.logger).to receive(:warn).at_least(:once)
        params[:label] = 'a' * 256
        obj = register
        expect(obj.label).to eq('a' * 254)
      end
    end # context common cases
  end

  describe '#create_from_request' do
    subject(:create) { described_class.create_from_request(params) }

    let(:item) { klass.new(pid: pid) }

    before do
      allow(Dor::SuriService).to receive(:mint_id).and_return(pid)
      allow(Dor::SearchService).to receive(:query_by_id).and_return([])
      allow(ActiveFedora::Base).to receive(:connection_for_pid).and_return(mock_repo)
      allow(item).to receive(:save).and_return(true)
      allow(item).to receive(:create).and_return(true)
      allow(klass).to receive(:new).and_return(item)
    end

    context 'for an item' do
      let(:klass) { Dor::Item }
      let(:params) do
        {
          object_type: 'item',
          admin_policy: 'druid:fg890hi1234',
          label: 'web-archived-crawl for http://www.example.org',
          metadata_source: 'label',
          source_id: 'sul:SOMETHING-www.example.org'
        }
      end

      it 'creates a new object, indexes it immediately and creates and event' do
        expect(create).to be_kind_of Dor::RegistrationResponse
        expect(klass).to have_received(:new)
          .with(
            hash_including(admin_policy_object_id: apo.id,
                           label: 'web-archived-crawl for http://www.example.org',
                           source_id: 'sul:SOMETHING-www.example.org')
          )
        expect(item.rightsMetadata.content).to be_equivalent_to apo.defaultObjectRights.content
        expect(a_request(:post, 'https://dor-indexing-app.server/reindex/druid:ab123cd4567')).to have_been_made
        expect(EventFactory).to have_received(:create)
      end

      context 'when other_id is provided' do
        let(:params) do
          {
            object_type: 'item',
            admin_policy: 'druid:fg890hi1234',
            label: 'web-archived-crawl for http://www.example.org',
            source_id: 'sul:SOMETHING-www.example.org',
            metadata_source: 'label',
            other_id: other_id
          }
        end

        context 'when other_id has no colon' do
          let(:other_id) { 'no-colon' }

          it 'is successful' do
            expect { create }.not_to raise_error
          end
        end

        context 'when other_id has one colon' do
          let(:other_id) { 'catkey:000' }

          it 'is successful' do
            expect { create }.not_to raise_error
          end
        end

        context 'when other_id has many colons' do
          let(:other_id) { 'catkey:oop:sie' }

          it 'is successful' do
            expect { create }.not_to raise_error
          end
        end
      end
    end

    context 'for an APO' do
      let(:klass) { Dor::AdminPolicyObject }

      let(:params) do
        {
          object_type: 'adminPolicy',
          admin_policy: 'druid:fg890hi1234',
          metadata_source: 'label',
          label: 'Testing apo'
        }
      end

      it 'is successful' do
        expect(create).to be_kind_of Dor::RegistrationResponse
        expect(klass).to have_received(:new).with(
          hash_including(admin_policy_object_id: apo.id,
                         label: 'Testing apo')
        )
        expect(item.rightsMetadata.content).to be_equivalent_to apo.defaultObjectRights.content
        expect(EventFactory).to have_received(:create)
      end
    end
  end
end
