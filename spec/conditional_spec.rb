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
require 'j2119/conditional'

describe J2119::RoleNotPresentCondition do

  it 'should fail on an excluded role' do
    cut = J2119::RoleNotPresentCondition.new(['foo', 'bar'])
    json = JSON.parse '{ "bar": 1 }'
    expect(cut.constraint_applies(json, [ 'foo' ])).to eq(false)
  end

  it 'should succeed on a non-excluded role' do
    cut = J2119::RoleNotPresentCondition.new(['foo', 'bar'])
    json = JSON.parse '{ "bar": 1 }'
    expect(cut.constraint_applies(json, [ 'baz' ])).to eq(true)
  end
end
