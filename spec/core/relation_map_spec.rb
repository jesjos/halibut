require_relative '../spec_helper'

require 'halibut/core/relation_map'

describe Halibut::Core::RelationMap do
  subject { Halibut::Core::RelationMap.new }

  it "is empty" do
    assert_empty subject
  end

  describe '#add' do
    context "when there was no prior relation" do
      it "has one relation" do
        subject.add 'first', { value: 'first'}
        assert_equal 'first', subject['first'].first[:value]
      end
    end

    context "when there was prior relation" do
      context "and the relation was a single object" do
        it "has an array of two relations" do
          subject.add 'first', { value: 'first'}
          subject.add 'first', { value: 'second'}

          subject['first'].length.must_equal 2
          subject['first'].first[:value].must_equal 'first'
          subject['first'].last[:value].must_equal  'second'
        end
      end
    end

    # todo: throw an exception if add receives a value that does not respond to to_hash
    it 'throws an exception if item does not respond to #to_hash' do
      assert_raises(ArgumentError) do
        subject.add 'first', 'not-hashable'
      end
    end
  end

  describe '#to_hash' do
    describe 'single item and multi item relations' do
      it 'generates single item relations correctly' do
        subject.add('person', { name: 'bob' })

        subject.to_hash['person'][:name].must_equal 'bob'
      end

      it 'handles single item array relations' do
        value = [{ name: 'bob' }]
        subject.add('person', [{ name: 'bob' }])

        hashed = subject.to_hash
        hashed['person'].must_equal value
      end

      it 'generates multi item relations correctly' do
        subject.add('person', { name: 'bob' })
        subject.add('person', { name: 'floyd' })

        hashed_people = subject.to_hash['person']
        hashed_people.length.must_equal 2
        hashed_people[0][:name].must_equal 'bob'
        hashed_people[1][:name].must_equal 'floyd'
      end
    end
  end
end
