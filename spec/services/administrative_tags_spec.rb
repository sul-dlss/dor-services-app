# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AdministrativeTags do
  let(:item_with_db_tags) { Dor::Item.new(pid: 'druid:aa123bb7890') }
  let(:item_without_db_tags) { Dor::Item.new(pid: 'druid:bc234dg8901') }

  describe '.for' do
    let(:instance) { instance_double(described_class, for: nil) }

    before do
      allow(described_class).to receive(:new).and_return(instance)
    end

    it 'calls #for on a new instance' do
      described_class.for(item: item_with_db_tags)
      expect(instance).to have_received(:for).once
    end
  end

  describe '.create' do
    let(:instance) { instance_double(described_class, create: nil) }

    before do
      allow(described_class).to receive(:new).and_return(instance)
    end

    it 'calls #create on a new instance' do
      described_class.create(item: item_with_db_tags, tags: ['What : Ever'])
      expect(instance).to have_received(:create).once.with(tags: ['What : Ever'])
    end
  end

  describe '.update' do
    let(:instance) { instance_double(described_class, update: nil) }

    before do
      allow(described_class).to receive(:new).and_return(instance)
    end

    it 'calls #update on a new instance' do
      described_class.update(item: item_with_db_tags, current: 'What : Ever', new: 'What : Ever : 2')
      expect(instance).to have_received(:update).once.with(current: 'What : Ever', new: 'What : Ever : 2')
    end
  end

  describe '.destroy' do
    let(:instance) { instance_double(described_class, destroy: nil) }

    before do
      allow(described_class).to receive(:new).and_return(instance)
    end

    it 'calls #destroy on a new instance' do
      described_class.destroy(item: item_with_db_tags, tag: 'What : Ever')
      expect(instance).to have_received(:destroy).once.with(tag: 'What : Ever')
    end
  end

  describe '#for' do
    before do
      create(:administrative_tag, druid: item_with_db_tags.pid, tag: 'Foo : Bar')
      create(:administrative_tag, druid: item_with_db_tags.pid, tag: 'Bar : Baz : Quux')
    end

    context 'with matching rows in the database' do
      it 'returns administrative tags from the database' do
        expect(described_class.for(item: item_with_db_tags)).to eq(['Foo : Bar', 'Bar : Baz : Quux'])
      end
    end

    context 'without matching rows in the database' do
      before do
        Dor::TagService.add(item_without_db_tags, 'One : Two : Three')
      end

      it 'returns administrative tags from identity metadata XML' do
        expect(described_class.for(item: item_without_db_tags)).to eq(['One : Two : Three'])
      end
    end
  end

  describe '#create' do
    before do
      # Don't actually manipulate the database
      allow(AdministrativeTag).to receive(:create)
    end

    let(:new_tags) { ['One : Two', 'A : B : C'] }

    it 'creates new administrative tags' do
      described_class.create(item: item_with_db_tags, tags: new_tags)

      expect(AdministrativeTag).to have_received(:create)
        .with(druid: item_with_db_tags.pid, tag: 'One : Two').once
      expect(AdministrativeTag).to have_received(:create)
        .with(druid: item_with_db_tags.pid, tag: 'A : B : C').once
    end

    context 'when no tags for druid exist but legacy tags do exist' do
      before do
        Dor::TagService.add(item_without_db_tags, 'One : Two : Three')
        Dor::TagService.add(item_without_db_tags, 'One : Two : Three : Four')
      end

      it 'adds tags from Fedora to the database' do
        described_class.create(item: item_without_db_tags, tags: new_tags)

        expect(AdministrativeTag).to have_received(:create)
          .with(druid: item_without_db_tags.pid, tag: 'One : Two : Three').once
        expect(AdministrativeTag).to have_received(:create)
          .with(druid: item_without_db_tags.pid, tag: 'One : Two : Three : Four').once
      end
    end
  end

  describe '#update' do
    before do
      # Don't actually manipulate the database
      allow(AdministrativeTag).to receive(:find_by!).and_return(fake_record)
    end

    let(:current_tag) { 'One : Two' }
    let(:fake_record) { instance_double(AdministrativeTag, update: nil) }
    let(:new_tag) { 'A : B : C' }

    it 'updates the administrative tag' do
      described_class.update(item: item_with_db_tags, current: current_tag, new: new_tag)

      expect(AdministrativeTag).to have_received(:find_by!)
        .with(druid: item_with_db_tags.pid, tag: current_tag).once
      expect(fake_record).to have_received(:update)
        .with(tag: new_tag).once
    end

    context 'when no tags for druid exist but legacy tags do exist' do
      before do
        Dor::TagService.add(item_without_db_tags, current_tag)
        Dor::TagService.add(item_without_db_tags, 'One : Two : Three : Four')
        # Don't actually manipulate the database
        allow(AdministrativeTag).to receive(:create)
      end

      it 'adds tags from Fedora to the database then updates one' do
        described_class.update(item: item_without_db_tags, current: current_tag, new: new_tag)

        expect(AdministrativeTag).to have_received(:create)
          .with(druid: item_without_db_tags.pid, tag: current_tag).once
        expect(AdministrativeTag).to have_received(:create)
          .with(druid: item_without_db_tags.pid, tag: 'One : Two : Three : Four').once
        expect(AdministrativeTag).to have_received(:find_by!)
          .with(druid: item_without_db_tags.pid, tag: current_tag).once
        expect(fake_record).to have_received(:update)
          .with(tag: new_tag).once
      end
    end
  end

  describe '#destroy' do
    before do
      # Don't actually manipulate the database
      allow(AdministrativeTag).to receive(:find_by!).and_return(fake_record)
    end

    let(:tag) { 'One : Two' }
    let(:fake_record) { instance_double(AdministrativeTag, destroy: nil) }

    it 'destroys the administrative tag' do
      described_class.destroy(item: item_with_db_tags, tag: tag)

      expect(AdministrativeTag).to have_received(:find_by!)
        .with(druid: item_with_db_tags.pid, tag: tag).once
      expect(fake_record).to have_received(:destroy).once
    end

    context 'when no tags for druid exist but legacy tags do exist' do
      before do
        Dor::TagService.add(item_without_db_tags, tag)
        Dor::TagService.add(item_without_db_tags, 'One : Two : Three : Four')
        # Don't actually manipulate the database
        allow(AdministrativeTag).to receive(:create)
      end

      it 'adds tags from Fedora to the database then destroys one' do
        described_class.destroy(item: item_without_db_tags, tag: tag)

        expect(AdministrativeTag).to have_received(:create)
          .with(druid: item_without_db_tags.pid, tag: tag).once
        expect(AdministrativeTag).to have_received(:create)
          .with(druid: item_without_db_tags.pid, tag: 'One : Two : Three : Four').once
        expect(AdministrativeTag).to have_received(:find_by!)
          .with(druid: item_without_db_tags.pid, tag: tag).once
        expect(fake_record).to have_received(:destroy).once
      end
    end
  end
end
