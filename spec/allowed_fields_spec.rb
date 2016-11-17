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
require 'j2119/allowed_fields'

describe J2119::AllowedFields do

  it 'should return a positive answer if appropriate' do
    cut = J2119::AllowedFields.new
    cut.set_allowed('foo', 'bar')
    expect(cut.allowed?([ 'foo' ], 'bar')).to be true
    expect(cut.allowed?([ 'bar', 'baz', 'foo' ], 'bar')).to be true
  end

  it 'should return a negative answer if appropriate' do
    cut = J2119::AllowedFields.new
    cut.set_allowed('foo', 'bar')
    expect(cut.allowed?([ 'foo' ], 'baz')).to be false
    expect(cut.allowed?([ 'bar', 'baz', 'foo' ], 'baz')).to be false
  end

  it 'should survive wonky queries' do
    cut = J2119::AllowedFields.new
    cut.set_allowed('foo', 'bar')
    expect(!cut.allowed?([ 'boo' ], 'baz')).to be_truthy 
    expect(!cut.allowed?([ ], 'baz')).to be_truthy 
  end

end
