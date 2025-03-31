# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MemberService do
  let(:members) { described_class.for(collection_druid, publishable:) }

  let(:collection_druid) { 'druid:bc123df4567' }
  let(:publishable) { false }

  let(:repository_object1) { create(:repository_object) }
  let(:repository_object2) { create(:repository_object) }
  let(:repository_object3) { create(:repository_object) }

  before do
    # Opened
    repository_object_version1 = create(:repository_object_version, version: 2, is_member_of: [collection_druid],
                                                                    repository_object: repository_object1)
    repository_object1.update!(head_version: repository_object_version1, opened_version: repository_object_version1)

    # Closed, with Cocina
    repository_object_version2 = create(:repository_object_version, version: 2, is_member_of: [collection_druid],
                                                                    repository_object: repository_object2,
                                                                    closed_at: Time.current)
    repository_object2.update!(head_version: repository_object_version2,
                               last_closed_version: repository_object_version2, opened_version: nil)

    # Closed, without Cocina
    repository_object_version3 = create(:repository_object_version, version: 2, is_member_of: [collection_druid],
                                                                    repository_object: repository_object3,
                                                                    closed_at: Time.current, cocina_version: nil)
    repository_object3.update!(
      head_version: repository_object_version3,
      last_closed_version: repository_object_version3,
      opened_version: create(:repository_object_version, version: 3, is_member_of: [collection_druid],
                                                         repository_object: repository_object3)
    )

    # Not a member
    create(:repository_object)
  end

  describe '.for' do
    context 'when collection has members' do
      it 'returns members' do
        expect(members).to contain_exactly(repository_object1.external_identifier,
                                           repository_object2.external_identifier,
                                           repository_object3.external_identifier)
      end
    end

    context 'when collection has no members' do
      let(:members) { described_class.for('druid:cc123df4568') }

      it 'returns no members' do
        expect(members).to be_empty
      end
    end

    context 'when only publishable members' do
      let(:publishable) { true }

      it 'returns members' do
        expect(members).to eq [repository_object2.external_identifier]
      end
    end
  end
end
