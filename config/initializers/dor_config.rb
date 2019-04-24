# frozen_string_literal: true

Dor.configure do
  ssl do
    cert_file Settings.SSL.CERT_FILE
    key_file Settings.SSL.KEY_FILE
    key_pass Settings.SSL.KEY_PASS
  end

  fedora do
    url Settings.FEDORA_URL
  end

  solr do
    url Settings.SOLRIZER_URL
  end

  workflow do
    url Settings.WORKFLOW_URL
    logfile Settings.WORKFLOW.LOGFILE
    shift_age Settings.WORKFLOW.SHIFT_AGE
  end

  dor_services do
    url Settings.DOR_SERVICES_URL
  end

  suri do
    mint_ids     Settings.SURI.MINT_IDS
    id_namespace Settings.SURI.ID_NAMESPACE
    url          Settings.SURI.URL
    user         Settings.SURI.USER
    pass         Settings.SURI.PASS
  end

  # Configure the client that connects to the catalog service during object registration
  metadata do
    catalog.url Settings.METADATA.CATALOG_URL
    catalog.user Settings.METADATA.CATALOG_USER
    catalog.pass Settings.METADATA.CATALOG_PASS
  end

  stomp do
    client_id Settings.STOMP_CLIENT_ID
  end

  content do
    content_user     Settings.CONTENT.USER
    content_base_dir Settings.CONTENT.BASE_DIR
    content_server   Settings.CONTENT.SERVER_HOST
    sdr_server       Settings.CONTENT.SDR_SERVER_URL
    sdr_user         Settings.CONTENT.SDR_USER
    sdr_pass         Settings.CONTENT.SDR_PASSWORD
  end

  status do
    indexer_url Settings.STATUS_INDEXER_URL
  end

  stacks do
    document_cache_storage_root Settings.STACKS.DOCUMENT_CACHE_STORAGE_ROOT
    document_cache_host         Settings.STACKS.DOCUMENT_CACHE_HOST
    document_cache_user         Settings.STACKS.DOCUMENT_CACHE_USER
    local_workspace_root        Settings.STACKS.LOCAL_WORKSPACE_ROOT
    storage_root                Settings.STACKS.STORAGE_ROOT
    host                        Settings.STACKS.HOST
    user                        Settings.STACKS.USER
    local_stacks_root           Settings.STACKS.LOCAL_STACKS_ROOT
    local_document_cache_root   Settings.STACKS.LOCAL_DOCUMENT_CACHE_ROOT
    local_recent_changes        Settings.STACKS.LOCAL_RECENT_CHANGES
    url                         Settings.STACKS.URL
    iiif_profile                'http://iiif.io/api/image/2/level1.json'
  end

  indexing_svc do
    log Settings.INDEXER.LOG
    log_date_format_str Settings.DATE_FORMAT_STR
    log_rotation_interval Settings.INDEXER.LOG_ROTATION_INTERVAL
  end

  cleanup do
    local_workspace_root Settings.CLEANUP.LOCAL_WORKSPACE_ROOT
    local_assembly_root  Settings.CLEANUP.LOCAL_ASSEMBLY_ROOT
    local_export_home    Settings.CLEANUP.LOCAL_EXPORT_HOME
  end

  release do
    symphony_path Settings.RELEASE.SYMPHONY_PATH
    write_marc_script Settings.RELEASE.WRITE_MARC_SCRIPT
    purl_base_uri Settings.RELEASE.PURL_BASE_URI
  end

  goobi do
    url Settings.GOOBI.URL
    dpg_workflow_name Settings.GOOBI.DPG_WORKFLOW_NAME # the dpg workflow name to put into the XML
    default_goobi_workflow_name Settings.GOOBI.DEFAULT_GOOBI_WORKFLOW_NAME # the default goobi workflow name to use if none found in the object
    max_tries Settings.GOOBI.MAX_TRIES # the number of attempts to retry service calls before failing
    max_sleep_seconds Settings.GOOBI.MAX_SLEEP_SECONDS # max sleep seconds between tries
    base_sleep_seconds Settings.GOOBI.BASE_SLEEP_SECONDS # base sleep seconds between tries
  end

  purl_services do
    url Settings.purl_services_url
  end
end
