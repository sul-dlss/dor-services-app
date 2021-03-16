# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DeepEqual do
  it 'compares objects' do
    expect(described_class.match?('foo', 'foo')).to be true
    expect(described_class.match?('foo', 'bar')).to be false
  end

  it 'compares arrays ignoring order' do
    expect(described_class.match?(['foo', 'bar'], ['foo', 'bar'])).to be true
    expect(described_class.match?(['foo', 'bar'], ['bar', 'foo'])).to be true
    expect(described_class.match?(['foo', 'bar'], ['bar'])).to be false
  end

  it 'compares hashes' do
    expect(described_class.match?({ a: 'foo', b: 'bar' }, { a: 'foo', b: 'bar' })).to be true
    expect(described_class.match?({ a: 'foo', b: 'bar' }, { a: 'foo', c: 'bar' })).to be false
    expect(described_class.match?({ a: 'foo', b: 'bar' }, { a: 'foo', b: 'foo' })).to be false
  end

  it 'deep compares hashes' do
    expect(described_class.match?({ a: 'foo', b: ['foo', 'bar'] }, { a: 'foo', b: ['bar', 'foo'] })).to be true
    expect(described_class.match?({ a: 'foo', b: ['foo', 'bar'] }, { a: 'foo', b: ['bar'] })).to be false
  end
end
