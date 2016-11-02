cert_dir = File.join(File.dirname(__FILE__), '..', 'certs')

Dor.configure do
  fedora.url 'https://localhost/fedora'

  ssl do
    cert_file File.join(cert_dir, 'mycert.crt')
    key_file  File.join(cert_dir, 'mycert.key')
    key_pass  ''
  end

  suri do
    mint_ids true
    id_namespace 'druid'
    url 'http://localhost:8080'
    user 'user'
    pass 'password'
  end

  sdr do
    url 'http://localhost/sdr'
  end

  metadata do
    exist.url   'http://localhost/exist/rest/'
    catalog.url 'http://localhost/catalog/mods'
  end

  solr.url 'https://localhost/solr/argo_dev'
  workflow.url 'http://localhost/workflow/'

  stacks.local_workspace_root '/my/workspace'

  dor do
    service_user     'user'
    service_password 'password'
  end

  release do
    symphony_path './'
    write_marc_script 'bin/write_marc_record_test'
    purl_base_uri 'http://purl.stanford.edu'
  end

  goobi do
    url 'https://goobi-api-url'
    dpg_workflow_name 'goobiWF' # the dpg workflow name to put into the XML
    default_goobi_workflow_name 'Sample_workflow' # the default goobi workflow name to use if none found in the object
    max_tries 5 # the number of attempts to retry service calls before failing
    max_sleep_seconds 120 # max sleep seconds between tries
    base_sleep_seconds 10 # base sleep seconds between tries
  end
end

Dor::WorkflowArchiver.config.configure do
  db_login    'user'
  db_password 'password'
  db_uri          '//localhost:1521/SID'
  dor_service_uri 'http://user:password@localhost'
end
