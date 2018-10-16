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
require 'j2119/node_validator'
require 'j2119/role_finder'
require 'j2119/role_constraints'
require 'j2119/constraints'


describe J2119::NodeValidator do

  it 'should report problems with faulty fields' do
    role_finder = J2119::RoleFinder.new()
    role_constraints = J2119::RoleConstraints.new()
    cut = J2119::NodeValidator.new(FakeParser.new(role_constraints,
                                                  role_finder))
    roles = [ 'Role1' ]

    # among fields
    # 'a' should exist
    # 'b' should not exist
    # 'c' should be a float
    # 'd' should be an integer
    # 'e' should be a number
    # 'f' should be between 0 and 5
    json = JSON.parse('{"b":1,"c":1,"d":0.3,"e":true,"f":10}')

    constraints = [
      J2119::HasFieldConstraint.new('a'),
      J2119::DoesNotHaveFieldConstraint.new('b'),
      J2119::FieldTypeConstraint.new('c', :float, false, false),
      J2119::FieldTypeConstraint.new('d', :integer, false, false),
      J2119::FieldTypeConstraint.new('e', :numeric, false, false),
      J2119::FieldValueConstraint.new('f', { :min => 0, :max => 5 })
    ]

    constraints.each do |constraint|
      role_constraints.add('Role1', constraint)
    end

    problems = []
    cut.validate_node(json, 'x.y', roles, problems)
    expect(problems.size).to eq(constraints.size)
  end

  class FakeParser
    def initialize(rc, rf)
      @role_constraints = rc
      @role_finder = rf
    end

    def get_constraints(r)
      @role_constraints.get_constraints(r)
    end

    def find_more_roles(n, r)
      @role_finder.find_more_roles(n, r)
    end

    def find_grandchild_roles(r, f)
      @role_finder.find_grandchild_roles(r, f)
    end

    def find_child_roles(r, f)
      @role_finder.find_child_roles(r, f)
    end

    def field_allowed?(r, f)
      true
    end

    def allows_any?(f)
      false
    end
end
end
