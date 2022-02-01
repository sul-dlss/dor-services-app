# frozen_string_literal: true

# rubocop:disable Layout/LineLength
def build_identity_metadata_1
  '<identityMetadata>
  <sourceId source="sul">36105216275185</sourceId>
  <objectId>druid:bb987ch8177</objectId>
  <objectCreator>DOR</objectCreator>
  <objectLabel>A  new map of Africa</objectLabel>
  <objectType>item</objectType>
  <displayType>image</displayType>
  <adminPolicy>druid:dd051ys2703</adminPolicy>
  <otherId name="catkey">8832162</otherId>
  <otherId name="barcode">36105216275185</otherId>
  <otherId name="uuid">ff3ce224-9ffb-11e3-aaf2-0050569b3c3c</otherId>
  <tag>Project : Batchelor Maps : Batch 1</tag>
  <tag>LAB : MAPS</tag>
  <tag>DPG : Workflow : book_workflow</tag>
  <tag>Registered By : dfuzzell</tag>
  <tag>Remediated By : 4.15</tag>
  <release displayType="image" release="true" to="Searchworks" what="self" when="2015-07-27T21:43:27Z" who="lauraw15">true</release>
</identityMetadata>'
end

def build_identity_metadata_2
  '<identityMetadata>
    <sourceId source="sul">36105216275185</sourceId>
    <objectId>druid:bb987ch8177</objectId>
    <objectCreator>DOR</objectCreator>
    <objectLabel>A  new map of Africa</objectLabel>
    <objectType>collection</objectType>
    <displayType>image</displayType>
    <adminPolicy>druid:dd051ys2703</adminPolicy>
    <otherId name="catkey">8832162</otherId>
    <otherId name="uuid">ff3ce224-9ffb-11e3-aaf2-0050569b3c3c</otherId>
    <tag>Process : Content Type : Map</tag>
    <tag>Project : Batchelor Maps : Batch 1</tag>
    <tag>LAB : MAPS</tag>
    <tag>Registered By : dfuzzell</tag>
    <tag>Remediated By : 4.15.4</tag>
    <release displayType="image" release="false" to="Searchworks" what="collection" when="2015-07-27T21:43:27Z" who="lauraw15">false</release>
    </identityMetadata>'
end

def build_identity_metadata_3
  '<identityMetadata>
    <sourceId source="sul">36105216275185</sourceId>
    <objectId>druid:bb987ch8177</objectId>
    <objectCreator>DOR</objectCreator>
    <objectType>item</objectType>
    <objectLabel>A  new map of Africa</objectLabel>
    <adminPolicy>druid:dd051ys2703</adminPolicy>
    <otherId name="uuid">ff3ce224-9ffb-11e3-aaf2-0050569b3c3c</otherId>
    <otherId name="catkey">8832162</otherId>
    <otherId name="previous_catkey">123</otherId>
    <otherId name="previous_catkey">456</otherId>
    <otherId name="previous_catkey"/>
    <tag>Process : Content Type : Map</tag>
    <tag>Project : Batchelor Maps : Batch 1</tag>
    <tag>LAB : MAPS</tag>
    <tag>Registered By : dfuzzell</tag>
    <tag>Remediated By : 4.15.4</tag>
  </identityMetadata>'
end

def build_identity_metadata_4
  '<identityMetadata>
    <sourceId source="sul">36105216275185</sourceId>
    <objectId>druid:bb987ch8177</objectId>
    <objectCreator>DOR</objectCreator>
    <objectLabel>A  new map of Africa</objectLabel>
    <objectType>item</objectType>
    <displayType>image</displayType>
    <adminPolicy>druid:dd051ys2703</adminPolicy>
    <otherId name="barcode">36105216275185</otherId>
    <otherId name="uuid">ff3ce224-9ffb-11e3-aaf2-0050569b3c3c</otherId>
    <tag>Process : Content Type : Map</tag>
    <tag>Project : Batchelor Maps : Batch 1</tag>
    <tag>LAB : MAPS</tag>
    <tag>Registered By : dfuzzell</tag>
    <tag>Remediated By : 4.1</tag>
    <release displayType="image" release="false" to="Searchworks" what="self" when="2015-07-27T21:43:27Z" who="lauraw15">false</release>
  </identityMetadata>'
end

def build_identity_metadata_5
  '<identityMetadata>
    <sourceId source="sul">36105216275185</sourceId>
    <objectId>druid:bb987ch8177</objectId>
    <objectCreator>DOR</objectCreator>
    <objectLabel>A  new map of Africa</objectLabel>
    <objectType>item</objectType>
    <displayType>image</displayType>
    <adminPolicy>druid:dd051ys2703</adminPolicy>
    <otherId name="previous_catkey">123</otherId>
    <otherId name="previous_catkey">456</otherId>
    <otherId name="barcode">36105216275185</otherId>
    <otherId name="uuid">ff3ce224-9ffb-11e3-aaf2-0050569b3c3c</otherId>
    <tag>Process : Content Type : Map</tag>
    <tag>Project : Batchelor Maps : Batch 1</tag>
    <tag>LAB : MAPS</tag>
    <tag>Registered By : dfuzzell</tag>
    <tag>Remediated By : 4.1</tag>
    <release displayType="image" release="false" to="Searchworks" what="self" when="2015-07-27T21:43:27Z" who="lauraw15">false</release>
  </identityMetadata>'
end

def build_identity_metadata_6
  '<identityMetadata>
    <sourceId source="sul">36105216275185</sourceId>
    <objectId>druid:bb987ch8177</objectId>
    <objectCreator>DOR</objectCreator>
    <objectLabel>A  new map of Africa</objectLabel>
    <adminPolicy>druid:dd051ys2703</adminPolicy>
    <otherId name="uuid">ff3ce224-9ffb-11e3-aaf2-0050569b3c3c</otherId>
    <tag>Process : Content Type : Map</tag>
    <tag>Project : Batchelor Maps : Batch 1</tag>
    <tag>LAB : MAPS</tag>
    <tag>Registered By : dfuzzell</tag>
    <tag>Remediated By : 4.15.4</tag>
  </identityMetadata>'
end

def build_content_metadata_1
  '<contentMetadata objectId="wt183gy6220" type="map">
  <resource id="wt183gy6220_1" sequence="1" type="image">
  <label>Image 1</label>
  <file id="wt183gy6220_00_0001.jp2" mimetype="image/jp2" size="3182927">
  <imageData width="4531" height="3715"/>
  </file>
  </resource>
  </contentMetadata>'
end

def build_cocina_structural_metadata_1
  {
    contains: [{
      type: Cocina::Models::Vocab::Resources.image,
      externalIdentifier: 'wt183gy6220',
      label: 'Image 1',
      version: 1,
      structural: {
        contains: [{
          type: Cocina::Models::Vocab.file,
          externalIdentifier: 'wt183gy6220_1',
          label: 'Image 1',
          filename: 'wt183gy6220_00_0001.jp2',
          hasMimeType: 'image/jp2',
          size: 3_182_927,
          version: 1,
          access: {},
          administrative: {
            publish: false,
            sdrPreserve: false,
            shelve: false
          },
          hasMessageDigests: []
        }]
      }
    }]
  }
end

def build_cocina_structural_metadata_2
  {
    hasMemberOrders: [{
      members: ['cg767mn6478_1/2542A.jp2']
    }]
  }
end

def build_cocina_structural_metadata_3
  {
    contains: [{
      type: Cocina::Models::Vocab::Resources.image,
      externalIdentifier: 'wt183gy6220',
      label: 'File 1',
      version: 1,
      structural: {
        contains: [{
          type: Cocina::Models::Vocab.file,
          externalIdentifier: 'wt183gy6220_1',
          label: 'File 1',
          filename: 'some_file.pdf',
          hasMimeType: 'file/pdf',
          size: 3_182_927,
          version: 1,
          access: {},
          administrative: {
            publish: false,
            sdrPreserve: false,
            shelve: false
          },
          hasMessageDigests: []
        }]
      }
    }]
  }
end

def build_content_metadata_2
  '<contentMetadata objectId="wt183gy6220">
  </contentMetadata>'
end

def build_rels_ext
  '<rdf:RDF xmlns:fedora="info:fedora/fedora-system:def/relations-external#" xmlns:fedora-model="info:fedora/fedora-system:def/model#" xmlns:hydra="http://projecthydra.org/ns/relations#" xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">
    <rdf:Description rdf:about="info:fedora/druid:cs003qk0166">
    <hydra:isGovernedBy rdf:resource="info:fedora/druid:sq161jk2248"/>
    <fedora-model:hasModel rdf:resource="info:fedora/afmodel:Dor_Item"/>
    <fedora:isMemberOf rdf:resource="info:fedora/druid:xh235dd9059"/>
    <fedora:isMemberOfCollection rdf:resource="info:fedora/druid:xh235dd9059"/>
    <fedora:isConstituentOf rdf:resource="info:fedora/druid:hj097bm8879"/>
  </rdf:Description>
</rdf:RDF>'
end

def build_desc_metadata_1
  '<mods xmlns="http://www.loc.gov/mods/v3">
  <titleInfo>
  <title>Constituent label &amp; A Special character</title>
  </titleInfo></mods>'
end

def build_cocina_description_metadata_1(druid)
  {
    title: [{ value: 'Constituent label &amp; A Special character' }],
    purl: "https://purl.stanford.edu/#{Dor::PidUtils.remove_druid_prefix(druid)}"
  }
end

def build_identity_metadata_with_ckey
  '<identityMetadata>
  <sourceId source="sul">36105216275185</sourceId>
  <objectId>druid:bb333dd4444</objectId>
  <objectCreator>DOR</objectCreator>
  <objectLabel>A  new map of Africa</objectLabel>
  <objectType>item</objectType>
  <displayType>image</displayType>
  <adminPolicy>druid:dd051ys2703</adminPolicy>
  <otherId name="catkey">8832162</otherId>
  <otherId name="uuid">ff3ce224-9ffb-11e3-aaf2-0050569b3c3c</otherId>
  <tag>Process : Content Type : Map</tag>
  <tag>Project : Batchelor Maps : Batch 1</tag>
  <tag>LAB : MAPS</tag>
  <tag>Registered By : dfuzzell</tag>
  <tag>Remediated By : 4.15.4</tag>
  </identityMetadata>'
end

def build_rights_metadata_1
  '<rightsMetadata>
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
    <human type="useAndReproduction">User agrees that, where applicable, content will not be used to identify or to otherwise infringe the privacy or confidentiality rights of individuals. Content distributed via the Stanford Digital Repository may be subject to additional license and use restrictions applied by the depositor.</human>
   </use>
  </rightsMetadata>
  '
end

def build_rights_metadata_2
  '<rightsMetadata>
   <copyright>
    <human type="copyright">Courtesy of The Revs Institute for Automotive Research, Inc. All rights reserved unless otherwise indicated.</human>
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
    <human type="useAndReproduction">Users must contact The Revs Institute for Automotive Research, Inc. for re-use and reproduction information.</human>
   </use>
   <use>
    <human type="creativeCommons"/>
    <machine type="creativeCommons"/>
   </use>
  </rightsMetadata>
  '
end

def build_rights_metadata_3
  '<rightsMetadata>
    <access type="discover">
      <machine>
        <world/>
      </machine>
    </access>
    <access type="read">
      <machine>
        <location>spec</location>
      </machine>
    </access>
    <use>
      <human type="useAndReproduction">While Special Collections is the owner of the physical and digital items, permission to examine collection materials is not an authorization to publish. These materials are made available for use in research, teaching, and private study. Any transmission or reproduction beyond that allowed by fair use requires permission from the owners of rights, heir(s) or assigns. See: http://library.stanford.edu/spc/using-collections/permission-publish. Access Condition: Content is available for access via the Special Collections Reading Room.</human>
    </use>
    <copyright>
      <human>Materials may be subject to copyright.</human>
    </copyright>
  </rightsMetadata>
  '
end
# rubocop:enable Layout/LineLength
