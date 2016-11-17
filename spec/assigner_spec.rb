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
require 'j2119/assigner'
require 'j2119/role_constraints'
require 'j2119/constraints'
require 'j2119/role_finder'
require 'j2119/matcher'
require 'j2119/oxford'
require 'j2119/conditional'
require 'j2119/deduce'
require 'j2119/allowed_fields'

describe J2119::Assigner do

  it 'should attach a condition to a constraint' do
    assertion = {
      'role' => 'R',
      'modal' => 'MUST',
      'field_name' => 'foo',
      'excluded' => 'an A, a B, or a C'
    }
    constraints = J2119::RoleConstraints.new
    rf = J2119::RoleFinder.new
    matcher = J2119::Matcher.new('x')
    allowed_fields = J2119::AllowedFields.new
    cut = J2119::Assigner.new(constraints, rf, matcher, allowed_fields)
    ['A', 'B', 'C'].each {|x| matcher.add_role(x)}
    cut.assign_constraints(assertion)
    retrieved = constraints.get_constraints('R')
    c = retrieved[0]
    json = JSON.parse '{"a":1}'
    expect(c).to be_instance_of(J2119::HasFieldConstraint)
    ['A', 'B', 'C'].each do |role|
      expect(c.applies(json, [ role ])).to eq(false)
    end
    expect(c.applies(json, [ 'foo' ])).to eq(true)
  end

  it 'should handle a "non-zero ... less than" constraint properly' do
    assertion = {
      'role' => 'R',
      'modal' => 'MAY',
      'type' => 'nonnegative-integer',
      'field_name' => 'MaxAttempts',
      'relation' => 'less than',
      'target' => 99999999
    }
    constraints = J2119::RoleConstraints.new
    rf = J2119::RoleFinder.new
    matcher = J2119::Matcher.new('x')
    allowed_fields = J2119::AllowedFields.new
    cut = J2119::Assigner.new(constraints, rf, matcher, allowed_fields)
    cut.assign_constraints(assertion)
    retrieved = constraints.get_constraints('R')
  end

  it 'should assign an only_one_of constraint properly' do
    assertion = { 'role' => 'R',
                  'field_list' => '"foo", "bar", and "baz"' }
    constraints = J2119::RoleConstraints.new
    rf = J2119::RoleFinder.new
    matcher = J2119::Matcher.new('x')
    allowed_fields = J2119::AllowedFields.new
    cut = J2119::Assigner.new(constraints, rf, matcher, allowed_fields)
    cut.assign_only_one_of(assertion)
    retrieved = constraints.get_constraints('R')
    expect(retrieved[0]).to be_instance_of(J2119::OnlyOneOfConstraint)
  end

  it "should add a HasFieldConstraint if there's a MUST" do
    assertion = { 'role' => 'R', 'modal' => 'MUST', 'field_name' => 'foo' }
    constraints = J2119::RoleConstraints.new
    rf = J2119::RoleFinder.new
    matcher = J2119::Matcher.new('x')
    allowed_fields = J2119::AllowedFields.new
    cut = J2119::Assigner.new(constraints, rf, matcher, allowed_fields)
    cut.assign_constraints(assertion)
    retrieved = constraints.get_constraints('R')
    expect(retrieved[0]).to be_instance_of(J2119::HasFieldConstraint)
  end

  it "should add a DoesNotHaveFieldConstraint if there's a MUST NOT" do
    assertion = { 'role' => 'R', 'modal' => 'MUST NOT', 'field_name' => 'foo' }
    constraints = J2119::RoleConstraints.new
    rf = J2119::RoleFinder.new
    matcher = J2119::Matcher.new('x')
    allowed_fields = J2119::AllowedFields.new
    cut = J2119::Assigner.new(constraints, rf, matcher, allowed_fields)
    cut.assign_constraints(assertion)
    retrieved = constraints.get_constraints('R')
    expect(retrieved[0]).to be_instance_of(J2119::DoesNotHaveFieldConstraint)
  end

  it "should manage a complex type constraint " do
    assertion = { 'role' => 'R',
                  'modal' => 'MUST',
                  'field_name' => 'foo',
                  'type' => 'nonnegative-float'
                }
    constraints = J2119::RoleConstraints.new
    rf = J2119::RoleFinder.new
    matcher = J2119::Matcher.new('x')
    allowed_fields = J2119::AllowedFields.new
    cut = J2119::Assigner.new(constraints, rf, matcher, allowed_fields)
    cut.assign_constraints(assertion)
    retrieved = constraints.get_constraints('R')
    c = retrieved.select {|x| x.is_a?(J2119::HasFieldConstraint)}
    expect(c.size).to eq(1)
    c = retrieved.select {|x| x.is_a?(J2119::FieldTypeConstraint)}
    expect(c.size).to eq(1)
    c = retrieved.select {|x| x.is_a?(J2119::FieldValueConstraint)}
    expect(c.size).to eq(1)
  end

  it "should record a relational constraint " do
    assertion = { 'role' => 'R',
                  'modal' => 'MUST',
                  'field_name' => 'foo',
                  'type' => 'nonnegative-float',
                  'relation' => 'less than'
                }
    constraints = J2119::RoleConstraints.new
    rf = J2119::RoleFinder.new
    matcher = J2119::Matcher.new('x')
    allowed_fields = J2119::AllowedFields.new
    cut = J2119::Assigner.new(constraints, rf, matcher, allowed_fields)
    cut.assign_constraints(assertion)
    retrieved = constraints.get_constraints('R')
    c = retrieved.select {|x| x.is_a?(J2119::HasFieldConstraint)}
    expect(c.size).to eq(1)
    c = retrieved.select {|x| x.is_a?(J2119::FieldTypeConstraint)}
    expect(c.size).to eq(1)
    c = retrieved.select {|x| x.is_a?(J2119::FieldValueConstraint)}
    expect(c.size).to eq(2)
  end

  it "should record an is_a role" do
    assertion = { 'role' => 'R',
                  'newrole' => 'S' 
                }
    rf = J2119::RoleFinder.new
    constraints = J2119::RoleConstraints.new
    matcher = J2119::Matcher.new('x')
    allowed_fields = J2119::AllowedFields.new
    cut = J2119::Assigner.new(constraints, rf, matcher, allowed_fields)
    cut.assign_roles(assertion)
    json = JSON.parse('{"a": 3}')
    roles = [ 'R' ]
    rf.find_more_roles(json, roles)
    expect(roles).to eq([ 'R', 'S' ])
  end

  it "should correctly assign a field value role" do
    assertion = { 'role' => 'R',
                  'fieldtomatch' => 'f1',
                  'valtomatch' => 33,
                  'newrole' => 'S',
                  'val_match_present' => true}
    constraints = J2119::RoleConstraints.new
    rf = J2119::RoleFinder.new
    matcher = J2119::Matcher.new('R')
    allowed_fields = J2119::AllowedFields.new
    cut = J2119::Assigner.new(constraints, rf, matcher, allowed_fields)
    cut.assign_roles(assertion)
    json = JSON.parse '{ "f1": 33 }'
    roles = [ 'R' ]
    rf.find_more_roles(json, roles)
    expect(roles).to eq(['R', 'S'])
  end

  it "should process a child role in an assertion" do
    assertion = { 'role' => 'R',
                  'modal' => 'MUST',
                  'field_name' => 'a',
                  'child_type' => 'field',
                  'child_role' => 'bar'
                }
    constraints = J2119::RoleConstraints.new
    rf = J2119::RoleFinder.new
    matcher = J2119::Matcher.new('x')
    allowed_fields = J2119::AllowedFields.new
    cut = J2119::Assigner.new(constraints, rf, matcher, allowed_fields)
    cut.assign_constraints(assertion)
    json = JSON.parse('{"a": 3}')
    roles = [ 'R' ]
    field_roles = rf.find_grandchild_roles(roles, 'a')
    expect(field_roles).to eq([ 'bar' ])
  end

end
