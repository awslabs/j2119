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
require 'j2119/matcher'
require 'j2119/oxford'

describe J2119::Matcher do

  EACHOF_LINES = [
    "Each of a Pass State, a Task State, a Choice State, and a Parallel State MAY have a boolean field named \"End\".",
    "Each of a Succeed State and a Fail State is a \"Terminal State\".",
    "Each of a Task State and a Parallel State MAY have an object-array field named \"Catch\"; each member is a \"Catcher\"."
  ]
  ROLES = [ 'Pass State', 'Task State', 'Choice State', 'Parallel State',
            'Succeed State', 'Fail State', 'Task Tate' ]
  it 'should spot Each-of lines' do
    cut = J2119::Matcher.new('message')
    ROLES.each { |role| cut.add_role(role) }
    EACHOF_LINES.each do |line|
      expect(cut.eachof_match.match(line)).to be_truthy
    end
  end

  it 'should handle only-one-of lines' do
    line = 'A x MUST have only one of "Seconds", "SecondsPath", "Timestamp", and "TimestampPath".'
    cut = J2119::Matcher.new('x')
    expect(cut.is_only_one_match_line(line)).to be_truthy
    m = cut.only_one_match.match line
    expect(m).to be_truthy
    expect(m['role']).to eq('x')
    s = m['field_list']
    l = J2119::Oxford.break_string_list(s)
    ['Seconds', 'SecondsPath', 'Timestamp', 'TimestampPath'].each do |p|
      expect(l.include?(p)).to eq(true)
    end
    expect(l.size).to eq(4)
           
  end

  SPLIT_EACHOF_LINES = [
    [
      "A Pass State MAY have a boolean field named \"End\".",
      "A Task State MAY have a boolean field named \"End\".",
      "A Choice State MAY have a boolean field named \"End\".",
      "A Parallel State MAY have a boolean field named \"End\"."
    ],
    [
      "A Succeed State is a \"Terminal State\".",
      "A Fail State is a \"Terminal State\"."
    ],
    [
      "A Task State MAY have an object-array field named \"Catch\"; each member is a \"Catcher\".",
      "A Parallel State MAY have an object-array field named \"Catch\"; each member is a \"Catcher\"."
    ]
  ]
  it 'should properly disassemble each-of lines' do
    cut = J2119::Matcher.new('message')
    ROLES.each { |role| cut.add_role(role) }
    EACHOF_LINES.each do |line|
      wanted = SPLIT_EACHOF_LINES.shift
      J2119::Oxford.break_role_list(cut, line).each do |one_line|
        expect(wanted.include?(one_line)).to eq(true)
      end
    end
  end

  RDLINES = [
    "A State whose \"End\" field's value is true is a \"Terminal State\".",
    "Each of a Succeed State and a Fail state is a \"Terminal State\".",
    "A Choice Rule with a \"Variable\" field is a \"Comparison\"."
  ]
  it 'should spot role-def lines' do
    cut = J2119::Matcher.new('message')
    RDLINES.each do |line|
      expect(cut.is_role_def_line(line)).to be_truthy
    end
  end

  VALUE_BASED_ROLE_DEFS = [
    "A State whose \"End\" field's value is true is a \"Terminal State\".",
    "A State whose \"Comment\" field's value is \"Hi\" is a \"Frobble\".",
    "A State with a \"Foo\" field is a \"Bar\"."
  ]
  it 'should match value-based role defs' do
    cut = J2119::Matcher.new('State')
    
    VALUE_BASED_ROLE_DEFS.each do |line|
      expect(cut.roledef_match.match(line)).to be_truthy
    end

    m = cut.roledef_match.match(VALUE_BASED_ROLE_DEFS[0])
    expect(m['role']).to eq('State')
    expect(m['fieldtomatch']).to eq('End')
    expect(m['valtomatch']).to eq('true')
    expect(m['newrole']).to eq('Terminal State')
    expect(m['val_match_present']).to be_truthy

    m = cut.roledef_match.match(VALUE_BASED_ROLE_DEFS[1])
    expect(m['role']).to eq('State')
    expect(m['fieldtomatch']).to eq('Comment')
    expect(m['valtomatch']).to eq('"Hi"')
    expect(m['newrole']).to eq('Frobble')
    expect(m['val_match_present']).to be_truthy

    m = cut.roledef_match.match(VALUE_BASED_ROLE_DEFS[2])
    expect(m['role']).to eq('State')
    expect(m['newrole']).to eq('Bar')
    expect(m['with_a_field']).to be_truthy
  end

  it 'should match is_a role defs' do
    cut = J2119::Matcher.new('Foo')
    expect(cut.roledef_match.match('A Foo is a "Bar".')).to be_truthy
  end

  it 'should properly parse is_a role defs' do
    cut = J2119::Matcher.new('Foo')
    cut.add_role('Bar')
    c = cut.build_role_def('A Foo is a "Bar".')
    expect(c['val_match_present']).to eq(nil)
  end

  it 'should properly parse value-based role defs' do
    cut = J2119::Matcher.new('State')
    c = cut.build_role_def(VALUE_BASED_ROLE_DEFS[0])
    expect(c['role']).to eq('State')
    expect(c['fieldtomatch']).to eq('End')
    expect(c['valtomatch']).to eq('true')
    expect(c['newrole']).to eq('Terminal State')

    c = cut.build_role_def(VALUE_BASED_ROLE_DEFS[1])
    expect(c['role']).to eq('State')
    expect(c['fieldtomatch']).to eq('Comment')
    expect(c['valtomatch']).to eq('"Hi"')
    expect(c['newrole']).to eq('Frobble')
end

  LINES = [
    'A message MUST have an object field named "States"; each field is a "State".',
    'A message MUST have a negative-integer-array field named "StartAt".',
    'A message MAY have a string-array field named "StartAt".',
    'A message MUST NOT have a field named "StartAt".',
    'A message MUST have a field named one of "StringEquals", "StringLessThan", "StringGreaterThan", "StringLessThanEquals", "StringGreaterThanEquals", "NumericEquals", "NumericLessThan", "NumericGreaterThan", "NumericLessThanEquals", "NumericGreaterThanEquals", "BooleanEquals", "TimestampEquals", "TimestampLessThan", "TimestampGreaterThan", "TimestampLessThanEquals", or "TimestampGreaterThanEquals".'
  ]
  it 'should spot a simple constraint line' do
    cut = J2119::Matcher.new('message')
    LINES.each do |line|
      expect(cut.is_constraint_line(line)).to be_truthy
    end
  end

  it 'should spot a simple constraint line with new roles' do
    cut = J2119::Matcher.new('message')
    lines2 = LINES.map{|line| line.gsub('message', 'avatar')}
    cut.add_role('avatar')
    lines2.each do |line|
      expect(cut.is_constraint_line(line)).to be_truthy
    end
  end

  COND_LINES = [
    'An R1 MUST have an object field named "States"; each field is a "State".',
    'An R1 which is not an R2 MUST have an object field named "States"; each field is a "State".',
    'An R1 which is not an R2 or an R3 MUST NOT have a field named "StartAt".',
    'An R1 which is not an R2, an R3, or an R4 MUST NOT have a field named "StartAt".'
  ]
  it 'should catch a conditional on a constraint' do
    excludes = [
      nil,
      'an R2',
      'an R2 or an R3',
      'an R2, an R3, or an R4'
    ]
    cut = J2119::Matcher.new('R1')
    cut.add_role('R2')
    cut.add_role('R3')
    cut.add_role('R4')
    COND_LINES.each do |line|
      expect(cut.constraint_match.match(line)).to be_truthy
      m = cut.constraint_match.match(line)
      expect(m['excluded']).to eq(excludes.shift)
    end
  end

  it 'should match a reasonably complex constraint' do
    cut = J2119::Matcher.new('State')
    s = 'A State MUST have a string field named "Type" whose value MUST be one of "Pass", "Succeed", "Fail", "Task", "Choice", "Wait", or "Parallel".'
    expect(cut.constraint_match.match(s)).to be_truthy

    cut.add_role 'Retrier'
    s = 'A Retrier MAY have a nonnegative-integer field named "MaxAttempts" whose value MUST be less than 99999999.'
    expect(cut.constraint_match.match(s)).to be_truthy
  end

  it 'should build an enum constraint object' do
    cut = J2119::Matcher.new('State')
    s = 'A State MUST have a string field named "Type" whose value MUST be one of "Pass", "Succeed", "Fail", "Task", "Choice", "Wait", or "Parallel".'
    c = cut.build_constraint(s)
    expect(c['role']).to eq('State')
    expect(c['modal']).to eq('MUST')
    expect(c['type']).to eq('string')
    expect(c['field_name']).to eq('Type')
    expect(c['relation']).to be_nil
    expect(c['strings']).to eq('"Pass", "Succeed", "Fail", "Task", "Choice", "Wait", or "Parallel"')
    expect(c['child_type']).to be_nil
  end

  it 'should tokenize string lists properly' do
    cut = J2119::Matcher.new('x')
    expect(J2119::Matcher.tokenize_strings('"a"')).to eq([ 'a' ])
    expect(J2119::Matcher.tokenize_strings('"a" or "b"')).to eq([ 'a', 'b' ])
    expect(J2119::Matcher.tokenize_strings('"a", "b", or "c"')).to eq([ 'a', 'b', 'c'])
  end

  it 'should build a relational constraint object' do
    cut = J2119::Matcher.new('Retrier')
    s = 'A Retrier MAY have a nonnegative-integer field named "MaxAttempts" whose value MUST be less than 99999999.'
    c = cut.build_constraint(s)
    expect(c['role']).to eq('Retrier')
    expect(c['modal']).to eq('MAY')
    expect(c['type']).to eq('nonnegative-integer')
    expect(c['field_name']).to eq('MaxAttempts')
    expect(c['strings']).to be_nil
    expect(c['relation']).to eq('less than')
    expect(c['target']).to eq('99999999')
    expect(c['child_type']).to be_nil
  end

  it 'should build a constraint object with child type' do
    cut = J2119::Matcher.new('State Machine')
    s = 'A State Machine MUST have an object field named "States"; each field is a "State".'
    c = cut.build_constraint(s)
    expect(c['role']).to eq('State Machine')
    expect(c['modal']).to eq('MUST')
    expect(c['type']).to eq('object')
    expect(c['field_name']).to eq('States')
    expect(c['child_type']).to eq('field')
    expect(c['child_role']).to eq('State')

    line = 'A State Machine MAY have an object field named "Not"; its value is a "FOO".'
    expect(cut.constraint_match.match(line)).to be_truthy
    c = cut.build_constraint(line)
    expect(c['role']).to eq('State Machine')
    expect(c['modal']).to eq('MAY')
    expect(c['type']).to eq('object')
    expect(c['field_name']).to eq('Not')
    expect(c['child_role']).to eq('FOO')
  end

end
