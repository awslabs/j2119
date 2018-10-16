# coding: utf-8
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
require 'j2119/json_path_checker'

describe J2119::JSONPathChecker do

  it 'should allow default paths' do
    expect(J2119::JSONPathChecker.is_path?('$')).to be_truthy
    expect(J2119::JSONPathChecker.is_reference_path?('$')).to be_truthy
  end

  it 'should do simple paths' do
    expect(J2119::JSONPathChecker.is_path?('$.foo.bar')).to be_truthy
    expect(J2119::JSONPathChecker.is_path?('$..x')).to be_truthy
    expect(J2119::JSONPathChecker.is_path?('$.foo.bar.baz.biff..blecch')).to be_truthy
    expect(J2119::JSONPathChecker.is_path?('$.café_au_lait')).to be_truthy
    expect(J2119::JSONPathChecker.is_path?("$['foo']")).to be_truthy
    expect(J2119::JSONPathChecker.is_path?('$[3]')).to be_truthy
  end

  it 'should reject obvious botches' do
    expect(J2119::JSONPathChecker.is_path?('x')).to be nil
    expect(J2119::JSONPathChecker.is_path?('.x')).to be nil
    expect(J2119::JSONPathChecker.is_path?('x.y.z')).to be nil
    expect(J2119::JSONPathChecker.is_path?('$.~.bar')).to be nil
    expect(J2119::JSONPathChecker.is_reference_path?('x')).to be nil
    expect(J2119::JSONPathChecker.is_reference_path?('.x')).to be nil
    expect(J2119::JSONPathChecker.is_reference_path?('x.y.z')).to be nil
    expect(J2119::JSONPathChecker.is_reference_path?('$.~.bar')).to be nil
  end

  it 'should accept paths with bracket notation' do
    expect(J2119::JSONPathChecker.is_path?("$['foo']['bar']")).to be_truthy
    expect(J2119::JSONPathChecker.is_path?("$['foo']['bar']['baz']['biff']..blecch")).to be_truthy
    expect(J2119::JSONPathChecker.is_path?("$['café_au_lait']")).to be_truthy
  end

  it 'should accept some Jayway JsonPath examples' do
    paths = [
      '$.store.book[*].author',
      '$..author',
      '$.store.*',
      '$..book[2]',
      '$..book[0,1]',
      '$..book[:2]',
      '$..book[1:2]',
      '$..book[-2:]',
      '$..book[2:]',
      '$..*'
    ]
    paths.each do |path|
      expect(J2119::JSONPathChecker.is_path?(path)).to be_truthy
    end
  end

  it 'should allow reference paths' do
    paths = [
      '$.foo.bar',
      '$..x',
      '$.foo.bar.baz.biff..blecch',
      '$.café_au_lait',
      "$['foo']['bar']",
      "$['foo']['bar']['baz']['biff']..blecch",
      "$['café_au_lait']",
      '$..author',
      '$..book[2]'
    ]
    paths.each do |path|
      expect(J2119::JSONPathChecker.is_reference_path?(path)).to be_truthy
    end
  end

  it 'should distinguish between non-paths, paths, and reference paths' do
    paths = [
      '$.store.book[*].author',
      '$..author',
      '$.store.*',
      '$..book[2]',
      '$..book[0,1]',
      '$..book[:2]',
      '$..book[1:2]',
      '$..book[-2:]',
      '$..book[2:]',
      '$..*'
    ]
    reference_paths = [
      '$..author',
      '$..book[2]'
    ]
    paths.each do |path|
      expect(J2119::JSONPathChecker.is_path?(path)).to be_truthy
      if reference_paths.include?(path)
        expect(J2119::JSONPathChecker.is_reference_path?(path)).to be_truthy
      else
        expect(J2119::JSONPathChecker.is_reference_path?(path)).to be nil
      end
    end
    
  end
end
