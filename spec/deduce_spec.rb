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
require 'j2119/deduce'

describe J2119::Deduce do

  it 'spot types correctly' do
    expect(J2119::Deduce.value('"foo"')).to eq('foo')
    expect(J2119::Deduce.value('true')).to eq(true)
    expect(J2119::Deduce.value('false')).to eq(false)
    expect(J2119::Deduce.value('null')).to eq(nil)
    expect(J2119::Deduce.value('234')).to eq(234)
    expect(J2119::Deduce.value('25.411')).to eq(25.411)
  end
end

