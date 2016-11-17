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
require 'j2119/role_constraints'

describe J2119::RoleConstraints do
  it 'should successfully remember constraints' do
    cut = J2119::RoleConstraints.new
    c1 = J2119::HasFieldConstraint.new('foo')
    c2 = J2119::DoesNotHaveFieldConstraint.new('bar')
    cut.add('MyRole', c1)
    cut.add('MyRole', c2)
    cut.add('OtherRole', c1)
    r = cut.get_constraints('MyRole')
    expect(r.include?(c1)).to eq(true)
    expect(r.include?(c2)).to eq(true)
    expect(r.size).to eq(2)
    r = cut.get_constraints('OtherRole')
    expect(r.include?(c1)).to eq(true)
    expect(r.size).to eq(1)
    expect(cut.get_constraints('No Constraints').size).to eq(0)
  end
end
