# Copyright 2016 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"). You may
# not use this file except in compliance with the License. A copy of the
# License is located at
#
#    http://aws.amazon.com/apache2.0/
#
# or in the LICENSE.txt file accompanying this file. This file is distributed
# on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either
# express or implied. See the License for the specific language governing
# permissions and limitations under the License.

require 'json'
$:.unshift("#{File.expand_path(File.dirname(__FILE__))}/../lib")
require 'j2119/constraints'
require 'j2119/conditional'

describe J2119::Constraint do
  it 'should load and evaluate a condition' do
    cut = J2119::HasFieldConstraint.new('foo')
    json = JSON.parse '{ "bar": 1 }'
    expect(cut.applies(json, 'foo')).to eq(true)
    cond = J2119::RoleNotPresentCondition.new(['foo', 'bar'])
    cut.add_condition(cond)
    expect(cut.applies(json, [ 'foo' ])).to eq(false)
    expect(cut.applies(json, [ 'baz' ])).to eq(true)
  end
end

describe J2119::HasFieldConstraint do
  it 'should successfully detect a missing field' do
    cut = J2119::HasFieldConstraint.new('foo')
    json = JSON.parse '{ "bar": 1 }'
    problems = []
    cut.check(json, 'a.b.c', problems)
    expect(problems.size).to eq(1)
  end
  
  it 'should accept node with required field present' do
    cut = J2119::HasFieldConstraint.new('bar')
    json = JSON.parse '{ "bar": 1 }'
    problems = []
    cut.check(json, 'a.b.c', problems)
    expect(problems.size).to eq(0)
  end

end

describe J2119::NonEmptyConstraint do
  it 'should bypass an absent field' do
    cut = J2119::NonEmptyConstraint.new('foo')
    json = JSON.parse '{ "bar": 1 }'
    problems = []
    cut.check(json, 'a.b.c', problems)
    expect(problems.size).to eq(0)
  end

  it 'should bypass a non-array field' do
    cut = J2119::NonEmptyConstraint.new('foo')
    json = JSON.parse '{ "foo": 1 }'
    problems = []
    cut.check(json, 'a.b.c', problems)
    expect(problems.size).to eq(0)
  end

  it 'should OK a non-empty array' do
    cut = J2119::NonEmptyConstraint.new('foo')
    json = JSON.parse '{ "foo": [ 1 ] }'
    problems = []
    cut.check(json, 'a.b.c', problems)
    expect(problems.size).to eq(0)
  end

  it 'should catch an empty array' do
    cut = J2119::NonEmptyConstraint.new('foo')
    json = JSON.parse '{ "foo": [ ] }'
    problems = []
    cut.check(json, 'a.b.c', problems)
    expect(problems.size).to eq(1)
  end
end

describe J2119::DoesNotHaveFieldConstraint do
  it 'should successfully detect a forbidden field' do
    cut = J2119::DoesNotHaveFieldConstraint.new('foo')
    json = JSON.parse '{ "foo": 1 }'
    problems = []
    cut.check(json, 'a.b.c', problems)
    expect(problems.size).to eq(1)
  end

  it 'should accept node with required field present' do
    cut = J2119::DoesNotHaveFieldConstraint.new('bar')
    json = JSON.parse '{ "foo": 1 }'
    problems = []
    cut.check(json, 'a.b.c', problems)
    expect(problems.size).to eq(0)
  end

end

describe J2119::FieldValueConstraint do
  
  it "should be a silent no-op exit if the field isn't there" do
    cut = J2119::FieldValueConstraint.new('foo', {})
    json = JSON.parse('{"foo": 1}')
    problems = []
    cut.check(json, 'a.b.c', problems)
    expect(problems.size).to eq(0)
  end

  it "should detect a violation of enum policy" do
    cut = J2119::FieldValueConstraint.new('foo', :enum => [ 1, 2, 3] )
    json = JSON.parse('{"foo": 5}')
    problems = []
    cut.check(json, 'a.b.c', problems)
    expect(problems.size).to eq(1)
  end
  
  it "should detect a broken equals" do
    cut = J2119::FieldValueConstraint.new('foo', :equal => 12 )
    json = JSON.parse('{"foo": 12}')
    problems = []
    cut.check(json, 'a.b.c', problems)
    expect(problems.size).to eq(0)
    json = JSON.parse('{"foo": 3}')
    cut.check(json, 'a.b.c', problems)
    expect(problems.size).to eq(1)
  end

  it "should do min right" do
    cut = J2119::FieldValueConstraint.new('foo', :min => 1 )
    problems = []
    json = JSON.parse('{"foo": 1}')
    cut.check(json, 'a.b.c', problems)
    expect(problems.size).to eq(0)
    
    json = JSON.parse('{"foo": 0}')
    cut.check(json, 'a.b.c', problems)
    expect(problems.size).to eq(1)
  end
  
  it "should detect a broken floor" do
    cut = J2119::FieldValueConstraint.new('foo', :floor => 1 )
    json = JSON.parse('{"foo": 1}')
    problems = []
    cut.check(json, 'a.b.c', problems)
    expect(problems.size).to eq(1)
  end
  
  it "should detect a broken ceiling" do
    cut = J2119::FieldValueConstraint.new('foo', :ceiling => 3 )
    json = JSON.parse('{"foo": 3}')
    problems = []
    cut.check(json, 'a.b.c', problems)
    expect(problems.size).to eq(1)
  end

  it "should do max right" do
    cut = J2119::FieldValueConstraint.new('foo', :max => 3 )
    json = JSON.parse('{"foo": 3}')
    problems = []
    cut.check(json, 'a.b.c', problems)
    expect(problems.size).to eq(0)
    json = JSON.parse('{"foo": 4}')
    cut.check(json, 'a.b.c', problems)
    expect(problems.size).to eq(1)
  end

  it "should accept something within min/max range" do
    cut = J2119::FieldValueConstraint.new('foo', :min => 0, :max => 3 )
    json = JSON.parse('{"foo": 1}')
    problems = []
    cut.check(json, 'a.b.c', problems)
    expect(problems.size).to eq(0)
  end
end

describe J2119::OnlyOneOfConstraint do

  it "Should detect more than one errors" do
    cut = J2119::OnlyOneOfConstraint.new(['foo', 'bar', 'baz'])
    json = JSON.parse '{ "foo": 1, "bar": 2 }'
    problems = []
    cut.check(json, 'a.b.c', problems)
    expect(problems.size).to eq(1)
  end
end

describe J2119::FieldTypeConstraint do

  it "should be a silent no-op exit if the field isn't there" do
    cut = J2119::FieldTypeConstraint.new('foo', :integer, false, false)
    json = JSON.parse('{"bar": 1}')
    problems = []
    cut.check(json, 'a.b.c', problems)
    expect(problems.size).to eq(0)
  end
  
  it 'should successfully approve correct types' do
    tdata = { :string => '"foo"', :integer => 3, :float => 0.33,
              :boolean => false, :timestamp => '"2016-03-14T01:59:00Z"',
              :object => '{ "a": 1 }', :array => '[ 3, 4 ]',
              :json_path => "\"$.a.c[2,3]\"", :reference_path => "\"$.a['b'].d[3]\""
            }
    tdata.each do |type, value|
      cut = J2119::FieldTypeConstraint.new('foo', type, false, false)
      j = "{\"foo\": #{value}}"
      json = JSON.parse(j)
      problems = []
      cut.check(json, 'a.b.c', problems)
      expect(problems.size).to eq(0)
    end
  end
  
  it 'should successfully find incorrect types in an array field' do
    cut = J2119::FieldTypeConstraint.new('a', :integer, false, false)
    j = '{ "a": [ 1, 2, "foo", 4 ] }'
    json = JSON.parse(j)
    problems = []
    cut.check(json, 'a.b.c', problems)
    expect(problems.size).to eq(1)
  end

  it 'should successfully flag incorrect types' do
    tdata = { :string => 33, :integer => '"foo"', :float => 17,
              :boolean => 'null', :timestamp => '"2x16-03-14T01:59:00Z"',
              :json_path => '"blibble"', :reference_path => '"$.a.*"' }
    tdata.each do |type, value|
      cut = J2119::FieldTypeConstraint.new('foo', type, false, false)
      j = "{\"foo\": #{value}}"
      json = JSON.parse(j)
      problems = []
      cut.check(json, 'a.b.c', problems)
      expect(problems.size).to eq(1)
    end
  end

  it 'should handle nullable correctly' do
    tdata = { :a => nil }
    j = '{ "a": null }'
    json = JSON.parse j
    cut = J2119::FieldTypeConstraint.new('a', :string, false, false)
    problems = []
    cut.check(json, 'a.b.c', problems)
    expect(problems.size).to eq(1)
    cut = J2119::FieldTypeConstraint.new('a', :string, false, true)
    problems = []
    cut.check(json, 'a.b.c', problems)
    expect(problems.size).to eq(0)
  end

  it 'should handle array nesting constraints' do
    cut = J2119::FieldTypeConstraint.new('foo', :array, false, false)
    json = JSON.parse '{"foo": 1}'
    problems = []
    cut.check(json, 'a.b.c', problems)
    expect(problems.size).to eq(1)

    cut = J2119::FieldTypeConstraint.new('foo', :integer, true, false)
    json = JSON.parse '{"foo": [ "bar" ] }'
    problems = []
    cut.check(json, 'a.b.c', problems)
    expect(problems.size).to eq(1)
    json = JSON.parse '{"foo": [ 1 ] }'
    problems = []
    cut.check(json, 'a.b.c', problems)
    expect(problems.size).to eq(0)
  end

end
