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

$:.unshift("#{File.expand_path(File.dirname(__FILE__))}/../lib")
require 'json'
require 'j2119/role_finder'
require 'j2119/deduce'


describe J2119::RoleFinder do

  it 'should successfully assign an additional role based on a role' do
    cut = J2119::RoleFinder.new()
    json = JSON.parse('{"a": 3}')
    cut.add_is_a_role('OneRole', 'AnotherRole')
    roles = [ 'OneRole' ]
    cut.find_more_roles(json, roles)
    expect(roles.size).to eq(2)
    expect(roles.include?('AnotherRole')).to eq(true)
  end

  it 'should successfully assign a role based on field value' do
    cut = J2119::RoleFinder.new()
    json = JSON.parse('{"a": 3}')
    cut.add_field_value_role('MyRole', 'a', '3', 'NewRole')
    roles = [ 'MyRole' ]
    cut.find_more_roles(json, roles)
    expect(roles.size).to eq(2)
    expect(roles.include?('NewRole')).to eq(true)
  end

  it 'should successfully assign a role based on field presence' do
    cut = J2119::RoleFinder.new()
    json = JSON.parse('{"a": 3}')
    cut.add_field_presence_role('MyRole', 'a', 'NewRole')
    roles = [ 'MyRole' ]
    cut.find_more_roles(json, roles)
    expect(roles.size).to eq(2)
    expect(roles.include?('NewRole')).to eq(true)
  end

  it 'should successfully add a role to a grandchild field based on its name' do
    cut = J2119::RoleFinder.new()
    json = JSON.parse('{"a": 3}')
    cut.add_grandchild_role('MyRole', 'a', 'NewRole')
    roles = [ 'MyRole' ]
    grandchild_roles = cut.find_grandchild_roles(roles, 'a')
    expect(grandchild_roles.size).to eq(1)
    expect(grandchild_roles.include?('NewRole')).to eq(true)
  end

  it 'should successfully add a role to a child field based on its name' do
    cut = J2119::RoleFinder.new()
    json = JSON.parse('{"a": { "b": 3} }')
    cut.add_child_role('MyRole', 'a', 'NewRole')
    roles = [ 'MyRole' ]
    child_roles = cut.find_child_roles(roles, 'a')
    expect(child_roles.size).to eq(1)
    expect(child_roles.include?('NewRole')).to eq(true)
    
  end


end
