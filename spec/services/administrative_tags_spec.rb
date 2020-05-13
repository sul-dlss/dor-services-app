# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AdministrativeTags do
  let(:pid) { 'druid:aa123bb7890' }

  describe '.for' do
    let(:instance) { instance_double(described_class, for: nil) }

    before do
      allow(described_class).to receive(:new).and_return(instance)
    end

    it 'calls #for on a new instance' do
      described_class.for(pid: pid)
      expect(instance).to have_received(:for).once
    end
  end

  describe '.content_type' do
    let(:instance) { instance_double(described_class, content_type: nil) }

    before do
      allow(described_class).to receive(:new).and_return(instance)
    end

    it 'calls #content_type on a new instance' do
      described_class.content_type(pid: pid)
      expect(instance).to have_received(:content_type).once
    end
  end

  describe '.project' do
    let(:instance) { instance_double(described_class, project: nil) }

    before do
      allow(described_class).to receive(:new).and_return(instance)
    end

    it 'calls #project on a new instance' do
      described_class.project(pid: pid)
      expect(instance).to have_received(:project).once
    end
  end

  describe '.create' do
    let(:instance) { instance_double(described_class, create: nil) }

    before do
      allow(described_class).to receive(:new).and_return(instance)
    end

    it 'calls #create on a new instance' do
      described_class.create(pid: pid, tags: ['What : Ever'])
      expect(instance).to have_received(:create).once.with(tags: ['What : Ever'], replace: false)
    end
  end

  describe '.update' do
    let(:instance) { instance_double(described_class, update: nil) }

    before do
      allow(described_class).to receive(:new).and_return(instance)
    end

    it 'calls #update on a new instance' do
      described_class.update(pid: pid, current: 'What : Ever', new: 'What : Ever : 2')
      expect(instance).to have_received(:update).once.with(current: 'What : Ever', new: 'What : Ever : 2')
    end
  end

  describe '.destroy' do
    let(:instance) { instance_double(described_class, destroy: nil) }

    before do
      allow(described_class).to receive(:new).and_return(instance)
    end

    it 'calls #destroy on a new instance' do
      described_class.destroy(pid: pid, tag: 'What : Ever')
      expect(instance).to have_received(:destroy).once.with(tag: 'What : Ever')
    end
  end

  describe '#for' do
    before do
      create(:administrative_tag, druid: pid, tag_label: create(:tag_label, tag: 'Foo : Bar'))
      create(:administrative_tag, druid: pid, tag_label: create(:tag_label, tag: 'Bar : Baz : Quux'))
    end

    it 'returns administrative tags from the database' do
      expect(described_class.for(pid: pid)).to eq(['Foo : Bar', 'Bar : Baz : Quux'])
    end
  end

  describe '#content_type' do
    context 'with a matching row in the database' do
      before do
        create(:administrative_tag, druid: pid, tag_label: create(:tag_label, tag: 'Process : Content Type : Map'))
      end

      it 'parses and returns the content type' do
        expect(described_class.content_type(pid: pid)).to eq(['Map'])
      end
    end

    context 'with more than one matching row in the database' do
      before do
        create(:administrative_tag, druid: pid, tag_label: create(:tag_label, tag: 'Process : Content Type : Map'))
        create(:administrative_tag, druid: pid, tag_label: create(:tag_label, tag: 'Process : Content Type : Media'))
      end

      it 'parses and returns the first content type' do
        expect(described_class.content_type(pid: pid)).to eq(['Map'])
      end
    end

    context 'with no content types' do
      before do
        create(:administrative_tag, druid: pid, tag_label: create(:tag_label, tag: 'Foo : Bar'))
      end

      it 'returns an empty array' do
        expect(described_class.content_type(pid: pid)).to eq([])
      end
    end
  end

  describe '#project' do
    context 'with a matching row in the database' do
      before do
        create(:administrative_tag, druid: pid, tag_label: create(:tag_label, tag: 'Project : Google Books'))
      end

      it 'parses and returns the project' do
        expect(described_class.project(pid: pid)).to eq(['Google Books'])
      end
    end

    context 'with more than one matching row in the database' do
      before do
        create(:administrative_tag, druid: pid, tag_label: create(:tag_label, tag: 'Project : Google Books'))
        create(:administrative_tag, druid: pid, tag_label: create(:tag_label, tag: 'Project : Fraggle Rock Collection'))
      end

      it 'parses and returns the first content type' do
        expect(described_class.project(pid: pid)).to eq(['Google Books'])
      end
    end

    context 'with no project' do
      before do
        create(:administrative_tag, druid: pid, tag_label: create(:tag_label, tag: 'Foo : Bar'))
      end

      it 'returns an empty array' do
        expect(described_class.project(pid: pid)).to eq([])
      end
    end
  end

  describe '#create' do
    let(:new_tags) { ['One : Two', 'A : B : C'] }

    it 'creates new administrative tags' do
      expect { described_class.create(pid: pid, tags: new_tags) }
        .to change { described_class.for(pid: pid).count }
        .by(new_tags.count)
    end

    context 'when one or more tags already exist' do
      before do
        create(:administrative_tag, druid: pid, tag_label: create(:tag_label, tag: new_tags.first))
      end

      it 'creates new administrative tags and returns existing ones' do
        expect { described_class.create(pid: pid, tags: new_tags) }
          .to change { described_class.for(pid: pid).count }
          .by(1)
      end
    end

    context 'when replacing tags' do
      before do
        create(:administrative_tag, druid: pid, tag_label: create(:tag_label, tag: 'Test : One'))
        create(:administrative_tag, druid: pid, tag_label: create(:tag_label, tag: 'Test : Two'))
        create(:administrative_tag, druid: pid, tag_label: create(:tag_label, tag: 'Test : Three'))
      end

      it 'destroys and creates new administrative tags' do
        expect { described_class.create(pid: pid, tags: new_tags, replace: true) }
          .to change { described_class.for(pid: pid).count }
          .by(-1)
      end
    end
  end

  describe '#update' do
    before do
      create(:administrative_tag, druid: pid, tag_label: create(:tag_label, tag: current_tag))
    end

    let(:current_tag) { 'One : Two' }
    let(:new_tag) { 'A : B : C' }

    it 'updates the administrative tag' do
      expect { described_class.update(pid: pid, current: current_tag, new: new_tag) }
        .to change { described_class.for(pid: pid) }
        .from([current_tag])
        .to([new_tag])
    end
  end

  describe '#destroy' do
    before do
      create(:administrative_tag, druid: pid, tag_label: create(:tag_label, tag: tag))
    end

    let(:tag) { 'One : Two' }

    it 'destroys the administrative tag' do
      expect { described_class.destroy(pid: pid, tag: tag) }
        .to change { described_class.for(pid: pid) }
        .from([tag])
        .to([])
    end
  end
end
