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
require 'j2119/oxford'
require 'j2119/matcher'

describe J2119::Oxford do

  it 'should show the underlying pattern working' do
    re = Regexp.new('^' + J2119::Oxford::BASIC + '$')
    expect(re.match('X')).to be_truthy
    expect(re.match('X or X')).to be_truthy
    expect(re.match('X, X, or X')).to be_truthy
    expect(re.match('X, X, X, or X')).to be_truthy
  end

  it 'should do a no-article no-capture no-connector match' do
    targets = [
      'a',
      'a or aa',
      'a, aa, or aaa',
      'a, aa, aaa, or aaaa'
    ]
    cut = Regexp.new('^' + J2119::Oxford.re('a+') + '$')
    targets.each do |t|
      expect(cut.match(t)).to be_truthy
    end
  end

  it 'should do one with capture, articles, and connector' do
    targets = [
      'an "asdg"',
      'a "foij2pe" and an "aiepw"',
      'an "alkvm 2", an "ap89wf", and a " lfdj a fddalfkj"',
      'an "aj89peww", a "", an "aslk9 ", and an "x"'
    ]
    re = J2119::Oxford.re('"([^"]*)"',
                          :connector => 'and',
                          :use_article => true,
                          :capture_name => 'capture_me')
    cut = Regexp.new('^' + re + '$')
    targets.each do |t|
      expect(cut.match(t)).to be_truthy
    end
  end

  OXFORD_LISTS = [
    "an R2",
    "an R2 or an R3",
    "an R2, an R3, or an R4"
  ]
  it 'should properly break up a role list' do
    wanted_pieces = [ [ "R2" ], [ "R2", "R3" ], [ "R2", "R3", "R4" ] ]
    matcher = J2119::Matcher.new('R1')
    [ 'R2', 'R3', 'R4' ].each { |role| matcher.add_role(role) }
    OXFORD_LISTS.each do |list|
      expect(J2119::Oxford.break_role_list(matcher, list)).to eq(wanted_pieces.shift)
    end
  end

  STRING_LISTS = [
    '"R2"',
    '"R2" or "R3"',
    '"R2", "R3", or "R4"'
  ]
  it 'should properly break up a string list' do
    wanted_pieces = [ [ "R2" ], [ "R2", "R3" ], [ "R2", "R3", "R4" ] ]
    STRING_LISTS.each do |list|
      expect(J2119::Oxford.break_string_list(list)).to eq(wanted_pieces.shift)
    end
  end

  
end
