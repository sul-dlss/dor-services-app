# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TicketTagMigrator do
  context 'when not a ticket tag' do
    it 'does not change the tag' do
      expect(described_class.call(tag: 'Registered By : mjgiarlo')).to eq([])
    end
  end

  context 'when a ticket tag requiring normalization' do
    it 'normalizes the tag' do
      expect(described_class.call(tag: 'Test : SPECTPAT-1234')).to eq(['Test', 'Ticket : SPECPAT-1234'])
    end
  end

  context 'when a project tag' do
    it 'does not change the tag' do
      expect(described_class.call(tag: 'Project : DIGREQ-1234')).to eq([])
    end
  end

  context 'when a tag has multiple parts before ticket part' do
    it 'preserves the parts before the ticket part' do
      expect(described_class.call(tag: 'Test1 : Test2 : DIGREQ-1234')).to eq(['Test1 : Test2', 'Ticket : DIGREQ-1234'])
    end
  end

  context 'when a ticket has no parts before ticket part' do
    it 'adds a Ticket prefix' do
      expect(described_class.call(tag: 'DIGREQ-1234 : Test1')).to eq(['Ticket : DIGREQ-1234 : Test1'])
    end
  end

  context 'when a ticket has no parts after ticket part' do
    it 'includes those parts in the Ticket tag' do
      expect(described_class.call(tag: 'Test1 : DIGREQ-1234 : Test2')).to eq(['Test1',
                                                                              'Ticket : DIGREQ-1234 : Test2'])
    end
  end

  context 'when first part is JIRA' do
    it 'drops the first part' do
      expect(described_class.call(tag: 'JIRA : DIGREQ-1234')).to eq(['Ticket : DIGREQ-1234'])
    end
  end

  context 'when first part is Decommissioned' do
    it 'drops the first part' do
      expect(described_class.call(tag: 'Decommissioned : DIGREQ-1234')).to eq(['Ticket : DIGREQ-1234'])
    end
  end

  context 'when already has ticket prefix' do
    it 'does not change the tag' do
      expect(described_class.call(tag: 'Ticket : DIGREQ-1234')).to eq([])
    end
  end
end
