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
require 'j2119'

GOOD = '{ ' +
       ' "StartAt": "x", ' +
       ' "States": {' +
       '  "x": {' +
       '    "Type": "Pass",' +
       '    "End": true ' +
       '  }' +
       ' } ' +
       '}'

WITH_ARRAY_RESULT =
       '{ ' +
       ' "StartAt": "No-op", ' +
       ' "States": { ' +
       '  "No-op": { ' +
       '   "Type": "Pass", ' +
       '   "ResultPath": "$.coords", ' +
       '   "Result": [ ' +
       '    "foo", ' +
       '    "bar", ' +
       '    { ' +
       '     "bazz": 123 ' +
       '    } ' +
       '   ], ' +
       '   "End": true ' +
       '  } ' +
       ' } ' +
       '} '

WITH_OBJECT_RESULT =
    '{ ' +
        ' "StartAt": "No-op", ' +
        ' "States": { ' +
        '  "No-op": { ' +
        '   "Type": "Pass", ' +
        '   "ResultPath": "$.coords", ' +
        '   "Result": { ' +
        '    "foo": { ' +
        '     "x-datum": 0.381018, ' +
        '     "y-datum": 622.2269926397355 ' +
        '    } ' +
        '   }, ' +
        '   "End": true ' +
        '  } ' +
        ' } ' +
        '} '


SCHEMA = File.dirname(__FILE__) + '/../data/AWL.j2119'

describe J2119::Validator do

  it 'should accept parsed JSON' do
    v = J2119::Validator.new SCHEMA
    j = JSON.parse GOOD
    p = v.validate j
    expect(p.empty?).to be true
  end
  
  it 'should accept JSON text' do
    v = J2119::Validator.new SCHEMA
    p = v.validate GOOD
    expect(p.empty?).to be true
  end
  
  it 'should read a JSON file' do
    v = J2119::Validator.new SCHEMA
    fn = "/tmp/#{$$}.tjf"
    f = File.open(fn, "w")
    f.write GOOD
    f.close
    
    p = v.validate fn
    File.delete fn
    expect(p.empty?).to be true
  end

  it 'should produce some sort of sane message with bad JSON' do
    v = J2119::Validator.new SCHEMA
    p = v.validate GOOD + 'x'
    expect(p.size).to eq(1)
  end

  it 'should allow Result to have array value' do
    v = J2119::Validator.new SCHEMA
    p = v.validate WITH_ARRAY_RESULT
    p.each {|problem| puts "P: #{problem}"}
    expect(p.size).to eq(0)
  end

  it 'should allow Result to have object value' do
    v = J2119::Validator.new SCHEMA
    p = v.validate WITH_OBJECT_RESULT
    p.each {|problem| puts "P: #{problem}"}
    expect(p.size).to eq(0)
  end

end
