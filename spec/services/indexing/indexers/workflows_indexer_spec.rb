# frozen_string_literal: true

require 'rails_helper'
RSpec.describe Indexing::Indexers::WorkflowsIndexer do
  let(:indexer) { described_class.new(id: 'druid:ab123cd4567') }

  describe '#to_solr' do
    subject(:solr_doc) { indexer.to_solr }

    let(:xml) do
      <<~XML
        <workflows objectId="druid:ab123cd4567">
          <workflow objectId="druid:ab123cd4567" id="accessionWF">
            <process version="1" priority="0" note="" lifecycle="submitted" laneId="default" elapsed="" attempts="0" datetime="2019-01-28T20:41:12+00:00" status="completed" name="start-accession"/>
            <process version="1" priority="0" note="common-accessioning-stage-a.stanford.edu" lifecycle="described" laneId="default" elapsed="0.258" attempts="0" datetime="2019-01-28T20:41:12+00:00" status="completed" name="descriptive-metadata"/>
            <process version="1" priority="0" note="common-accessioning-stage-b.stanford.edu" lifecycle="" laneId="default" elapsed="0.188" attempts="0" datetime="2019-01-28T20:41:12+00:00" status="completed" name="rights-metadata"/>
            <process version="1" priority="0" note="common-accessioning-stage-b.stanford.edu" lifecycle="" laneId="default" elapsed="0.255" attempts="0" datetime="2019-01-28T20:41:12+00:00" status="completed" name="content-metadata"/>
            <process version="1" priority="0" note="common-accessioning-stage-b.stanford.edu" lifecycle="" laneId="default" elapsed="0.948" attempts="0" datetime="2019-01-28T20:41:12+00:00" status="completed" name="technical-metadata"/>
            <process version="1" priority="0" note="common-accessioning-stage-b.stanford.edu" lifecycle="" laneId="default" elapsed="0.15" attempts="0" datetime="2019-01-28T20:41:12+00:00" status="completed" name="remediate-object"/>
            <process version="1" priority="0" note="common-accessioning-stage-b.stanford.edu" lifecycle="" laneId="default" elapsed="0.479" attempts="0" datetime="2019-01-28T20:41:12+00:00" status="completed" name="shelve"/>
            <process version="1" priority="0" note="common-accessioning-stage-b.stanford.edu" lifecycle="published" laneId="default" elapsed="1.188" attempts="0" datetime="2019-01-28T20:41:12+00:00" status="completed" name="publish"/>
            <process version="1" priority="0" note="common-accessioning-stage-b.stanford.edu" lifecycle="" laneId="default" elapsed="0.251" attempts="0" datetime="2019-01-28T20:41:12+00:00" status="completed" name="provenance-metadata"/>
            <process version="1" priority="0" note="common-accessioning-stage-b.stanford.edu" lifecycle="" laneId="default" elapsed="2.257" attempts="0" datetime="2019-01-28T20:41:12+00:00" status="completed" name="sdr-ingest-transfer"/>
            <process version="1" priority="0" note="preservationIngestWF completed on preservation-robots1-stage.stanford.edu" lifecycle="deposited" laneId="default" elapsed="1.0" attempts="0" datetime="2019-01-28T20:41:12+00:00" status="completed" name="sdr-ingest-received"/>
            <process version="1" priority="0" note="common-accessioning-stage-b.stanford.edu" lifecycle="" laneId="default" elapsed="0.246" attempts="0" datetime="2019-01-28T20:41:12+00:00" status="completed" name="reset-workspace"/>
            <process version="1" priority="0" note="common-accessioning-stage-a.stanford.edu" lifecycle="accessioned" laneId="default" elapsed="1.196" attempts="0" datetime="2019-01-28T20:41:12+00:00" status="completed" name="end-accession"/>
          </workflow>
          <workflow objectId="druid:ab123cd4567" id="assemblyWF">
            <process version="1" priority="0" note="" lifecycle="pipelined" laneId="default" elapsed="" attempts="0" datetime="2019-01-28T20:40:18+00:00" status="completed" name="start-assembly"/>
            <process version="1" priority="0" note="" lifecycle="" laneId="default" elapsed="" attempts="0" datetime="2019-01-28T20:40:18+00:00" status="skipped" name="jp2-create"/>
            <process version="1" priority="0" note="sul-robots1-test.stanford.edu" lifecycle="" laneId="default" elapsed="0.25" attempts="0" datetime="2019-01-28T20:40:18+00:00" status="completed" name="checksum-compute"/>
            <process version="1" priority="0" note="sul-robots1-test.stanford.edu" lifecycle="" laneId="default" elapsed="0.306" attempts="0" datetime="2019-01-28T20:40:18+00:00" status="completed" name="exif-collect"/>
            <process version="1" priority="0" note="sul-robots2-test.stanford.edu" lifecycle="" laneId="default" elapsed="0.736" attempts="0" datetime="2019-01-28T20:40:18+00:00" status="completed" name="accessioning-initiate"/>
            <process version="2" priority="0" note="" lifecycle="" laneId="default" elapsed="" attempts="0" datetime="2019-01-29T22:51:09+00:00" status="completed" name="start-assembly"/>
            <process version="2" priority="0" note="contentMetadata.xml exists" lifecycle="" laneId="default" elapsed="0.278" attempts="0" datetime="2019-01-29T22:51:09+00:00" status="skipped" name="content-metadata-create"/>
            <process version="2" priority="0" note="" lifecycle="" laneId="default" elapsed="0.0" attempts="0" datetime="2019-01-29T22:51:09+00:00" status="error" name="jp2-create"/>
            <process version="2" priority="0" note="" lifecycle="" laneId="default" elapsed="0.0" attempts="0" datetime="2019-01-29T22:51:09+00:00" status="queued" name="checksum-compute"/>
            <process version="2" priority="0" note="" lifecycle="" laneId="default" elapsed="0.0" attempts="0" datetime="2019-01-29T22:51:09+00:00" status="queued" name="exif-collect"/>
            <process version="2" priority="0" note="" lifecycle="" laneId="default" elapsed="0.0" attempts="0" datetime="2019-01-29T22:51:09+00:00" status="queued" name="accessioning-initiate"/>
          </workflow>
          <workflow objectId="druid:ab123cd4567" id="disseminationWF">
            <process version="1" priority="0" note="common-accessioning-stage-b.stanford.edu" lifecycle="" laneId="default" elapsed="0.826" attempts="0" datetime="2019-01-28T20:46:57+00:00" status="completed" name="cleanup"/>
          </workflow>
          <workflow objectId="druid:ab123cd4567" id="hydrusAssemblyWF">
            <process version="1" priority="0" note="" lifecycle="registered" laneId="default" elapsed="" attempts="0" datetime="2019-01-28T20:37:43+00:00" status="completed" name="start-deposit"/>
            <process version="1" priority="0" note="" lifecycle="" laneId="default" elapsed="0.0" attempts="0" datetime="2019-01-28T20:37:43+00:00" status="completed" name="submit"/>
            <process version="1" priority="0" note="" lifecycle="" laneId="default" elapsed="0.0" attempts="0" datetime="2019-01-28T20:37:43+00:00" status="completed" name="approve"/>
            <process version="1" priority="0" note="" lifecycle="" laneId="default" elapsed="0.0" attempts="0" datetime="2019-01-28T20:37:43+00:00" status="completed" name="start-assembly"/>
            <process version="2" priority="0" note="" lifecycle="" laneId="default" elapsed="0.0" attempts="0" datetime="2019-01-28T20:48:17+00:00" status="completed" name="submit"/>
            <process version="2" priority="0" note="" lifecycle="" laneId="default" elapsed="0.0" attempts="0" datetime="2019-01-28T20:48:17+00:00" status="completed" name="approve"/>
            <process version="2" priority="0" note="" lifecycle="" laneId="default" elapsed="0.0" attempts="0" datetime="2019-01-28T20:48:18+00:00" status="completed" name="start-assembly"/>
          </workflow>
          <workflow objectId="druid:ab123cd4567" id="versioningWF">
            <process version="2" priority="0" note="" lifecycle="opened" laneId="default" elapsed="" attempts="0" datetime="2019-01-28T20:48:16+00:00" status="completed" name="start-version"/>
            <process version="2" priority="0" note="" lifecycle="" laneId="default" elapsed="" attempts="1" datetime="2019-01-28T20:48:16+00:00" status="completed" name="submit-version"/>
            <process version="2" priority="0" note="" lifecycle="" laneId="default" elapsed="" attempts="1" datetime="2019-01-28T20:48:16+00:00" status="completed" name="start-accession"/>
          </workflow>
        </workflows>
      XML
    end

    let(:accession_json) do
      { 'processes' => [
        { 'name' => 'start-accession' },
        { 'name' => 'descriptive-metadata' },
        { 'name' => 'rights-metadata' },
        { 'name' => 'content-metadata' },
        { 'name' => 'technical-metadata' },
        { 'name' => 'remediate-object' },
        { 'name' => 'shelve' },
        { 'name' => 'publish' },
        { 'name' => 'provenance-metadata' },
        { 'name' => 'sdr-ingest-transfer' },
        { 'name' => 'sdr-ingest-received' },
        { 'name' => 'reset-workspace' },
        { 'name' => 'end-accession' }
      ] }
    end

    let(:assembly_json) do
      { 'processes' => [
        { 'name' => 'start-assembly' },
        { 'name' => 'content-metadata-create' },
        { 'name' => 'jp2-create' },
        { 'name' => 'checksum-compute' },
        { 'name' => 'exif-collect' },
        { 'name' => 'accessioning-initiate' }
      ] }
    end

    let(:dissemination_json) do
      {
        'processes' => [
          { 'name' => 'cleanup' }
        ]
      }
    end

    let(:hydrus_json) do
      { 'processes' => [
        { 'name' => 'start-deposit' },
        { 'name' => 'submit' },
        { 'name' => 'approve' },
        { 'name' => 'start-assembly' }
      ] }
    end

    let(:versioning_json) do
      { 'processes' => [
        { 'name' => 'start-version' },
        { 'name' => 'submit-version' },
        { 'name' => 'start-accession' }
      ] }
    end

    before do
      allow(Workflow::Service).to receive(:workflows).with(druid: 'druid:ab123cd4567').and_return(
        Dor::Services::Response::Workflows.new(xml: Nokogiri::XML(xml)).workflows
      )
      allow(Workflow::TemplateService).to receive(:template)
        .with(workflow_name: 'accessionWF').and_return(accession_json)
      allow(Workflow::TemplateService).to receive(:template)
        .with(workflow_name: 'assemblyWF').and_return(assembly_json)
      allow(Workflow::TemplateService).to receive(:template)
        .with(workflow_name: 'disseminationWF').and_return(dissemination_json)
      allow(Workflow::TemplateService).to receive(:template)
        .with(workflow_name: 'hydrusAssemblyWF').and_return(hydrus_json)
      allow(Workflow::TemplateService).to receive(:template)
        .with(workflow_name: 'versioningWF').and_return(versioning_json)
    end

    # WORKFLOW_SOLR = 'wf_ssim'
    # # field that indexes workflow name, process status then process name
    # WORKFLOW_WPS_SOLR = 'wf_wps_ssim'
    # WORKFLOW_WPS_SOLR_DV = 'wf_wps_ssimdv'
    # # field that indexes workflow name, process name then process status
    # WORKFLOW_WSP_SOLR = 'wf_wsp_ssim'
    # WORKFLOW_WSP_SOLR_DV = 'wf_wsp_ssimdv'
    # # field that indexes process status, workflowname then process name
    # WORKFLOW_SWP_SOLR = 'wf_swp_ssim'
    # WORKFLOW_SWP_SOLR_DV = 'wf_swp_ssimdv'
    # WORKFLOW_ERROR_SOLR = 'wf_error_ssim'

    it 'returns document' do
      expect(solr_doc['workflow_status_ssim']).to eq ['accessionWF|completed|0',
                                                      'assemblyWF|active|1',
                                                      'disseminationWF|completed|0',
                                                      'hydrusAssemblyWF|completed|0',
                                                      'versioningWF|completed|0']
      expected_wps = ['accessionWF',
                      'accessionWF:start-accession',
                      'accessionWF:start-accession:completed',
                      'accessionWF:descriptive-metadata',
                      'accessionWF:descriptive-metadata:completed',
                      'accessionWF:rights-metadata',
                      'accessionWF:rights-metadata:completed',
                      'accessionWF:content-metadata',
                      'accessionWF:content-metadata:completed',
                      'accessionWF:technical-metadata',
                      'accessionWF:technical-metadata:completed',
                      'accessionWF:remediate-object',
                      'accessionWF:remediate-object:completed',
                      'accessionWF:shelve',
                      'accessionWF:shelve:completed',
                      'accessionWF:publish',
                      'accessionWF:publish:completed',
                      'accessionWF:provenance-metadata',
                      'accessionWF:provenance-metadata:completed',
                      'accessionWF:sdr-ingest-transfer',
                      'accessionWF:sdr-ingest-transfer:completed',
                      'accessionWF:sdr-ingest-received',
                      'accessionWF:sdr-ingest-received:completed',
                      'accessionWF:reset-workspace',
                      'accessionWF:reset-workspace:completed',
                      'accessionWF:end-accession',
                      'accessionWF:end-accession:completed',
                      'assemblyWF',
                      'assemblyWF:start-assembly',
                      'assemblyWF:start-assembly:completed',
                      'assemblyWF:content-metadata-create',
                      'assemblyWF:content-metadata-create:skipped',
                      'assemblyWF:jp2-create',
                      'assemblyWF:jp2-create:error',
                      'assemblyWF:checksum-compute',
                      'assemblyWF:checksum-compute:queued',
                      'assemblyWF:exif-collect',
                      'assemblyWF:exif-collect:queued',
                      'assemblyWF:accessioning-initiate',
                      'assemblyWF:accessioning-initiate:queued',
                      'disseminationWF',
                      'disseminationWF:cleanup',
                      'disseminationWF:cleanup:completed',
                      'hydrusAssemblyWF',
                      'hydrusAssemblyWF:start-deposit',
                      'hydrusAssemblyWF:start-deposit:completed',
                      'hydrusAssemblyWF:submit',
                      'hydrusAssemblyWF:submit:completed',
                      'hydrusAssemblyWF:approve',
                      'hydrusAssemblyWF:approve:completed',
                      'hydrusAssemblyWF:start-assembly',
                      'hydrusAssemblyWF:start-assembly:completed',
                      'versioningWF',
                      'versioningWF:start-version',
                      'versioningWF:start-version:completed',
                      'versioningWF:submit-version',
                      'versioningWF:submit-version:completed',
                      'versioningWF:start-accession',
                      'versioningWF:start-accession:completed']
      expect(solr_doc['wf_wps_ssim']).to eq expected_wps
      expect(solr_doc['wf_wps_ssimdv']).to eq expected_wps

      expected_wsp = ['accessionWF',
                      'accessionWF:completed',
                      'accessionWF:completed:start-accession',
                      'accessionWF:completed:descriptive-metadata',
                      'accessionWF:completed:rights-metadata',
                      'accessionWF:completed:content-metadata',
                      'accessionWF:completed:technical-metadata',
                      'accessionWF:completed:remediate-object',
                      'accessionWF:completed:shelve',
                      'accessionWF:completed:publish',
                      'accessionWF:completed:provenance-metadata',
                      'accessionWF:completed:sdr-ingest-transfer',
                      'accessionWF:completed:sdr-ingest-received',
                      'accessionWF:completed:reset-workspace',
                      'accessionWF:completed:end-accession',
                      'assemblyWF',
                      'assemblyWF:completed',
                      'assemblyWF:completed:start-assembly',
                      'assemblyWF:skipped',
                      'assemblyWF:skipped:content-metadata-create',
                      'assemblyWF:error',
                      'assemblyWF:error:jp2-create',
                      'assemblyWF:queued',
                      'assemblyWF:queued:checksum-compute',
                      'assemblyWF:queued:exif-collect',
                      'assemblyWF:queued:accessioning-initiate',
                      'disseminationWF',
                      'disseminationWF:completed',
                      'disseminationWF:completed:cleanup',
                      'hydrusAssemblyWF',
                      'hydrusAssemblyWF:completed',
                      'hydrusAssemblyWF:completed:start-deposit',
                      'hydrusAssemblyWF:completed:submit',
                      'hydrusAssemblyWF:completed:approve',
                      'hydrusAssemblyWF:completed:start-assembly',
                      'versioningWF',
                      'versioningWF:completed',
                      'versioningWF:completed:start-version',
                      'versioningWF:completed:submit-version',
                      'versioningWF:completed:start-accession']
      expect(solr_doc['wf_wsp_ssim']).to eq expected_wsp
      expect(solr_doc['wf_wsp_ssimdv']).to eq expected_wsp

      expected_swp = ['completed',
                      'completed:accessionWF',
                      'completed:accessionWF:start-accession',
                      'completed:accessionWF:descriptive-metadata',
                      'completed:accessionWF:rights-metadata',
                      'completed:accessionWF:content-metadata',
                      'completed:accessionWF:technical-metadata',
                      'completed:accessionWF:remediate-object',
                      'completed:accessionWF:shelve',
                      'completed:accessionWF:publish',
                      'completed:accessionWF:provenance-metadata',
                      'completed:accessionWF:sdr-ingest-transfer',
                      'completed:accessionWF:sdr-ingest-received',
                      'completed:accessionWF:reset-workspace',
                      'completed:accessionWF:end-accession',
                      'completed:assemblyWF',
                      'completed:assemblyWF:start-assembly',
                      'skipped',
                      'skipped:assemblyWF',
                      'skipped:assemblyWF:content-metadata-create',
                      'error',
                      'error:assemblyWF',
                      'error:assemblyWF:jp2-create',
                      'queued',
                      'queued:assemblyWF',
                      'queued:assemblyWF:checksum-compute',
                      'queued:assemblyWF:exif-collect',
                      'queued:assemblyWF:accessioning-initiate',
                      'completed:disseminationWF',
                      'completed:disseminationWF:cleanup',
                      'completed:hydrusAssemblyWF',
                      'completed:hydrusAssemblyWF:start-deposit',
                      'completed:hydrusAssemblyWF:submit',
                      'completed:hydrusAssemblyWF:approve',
                      'completed:hydrusAssemblyWF:start-assembly',
                      'completed:versioningWF',
                      'completed:versioningWF:start-version',
                      'completed:versioningWF:submit-version',
                      'completed:versioningWF:start-accession']
      expect(solr_doc['wf_swp_ssim']).to eq expected_swp
      expect(solr_doc['wf_swp_ssimdv']).to eq expected_swp
    end
  end
end
