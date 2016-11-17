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
require 'j2119/parser'
require 'j2119/node_validator'
require 'j2119/role_constraints'
require 'j2119/role_finder'
require 'j2119/matcher'
require 'j2119/oxford'
require 'j2119/assigner'
require 'j2119/constraints'
require 'j2119/deduce'
require 'j2119/conditional'
require 'j2119/allowed_fields'
require 'j2119/json_path_checker'

describe J2119::Parser do

=begin
  it 'should match ROOT' do
    s = J2119::Parser::ROOT
    s = Regexp.new s
    expect(s.match('This document specifies a JSON object called a "State Machine".')).to be_truthy
  end
=end

  it 'should read them' do
    f = File.open("data/AWL.j2119", "r")
    p = J2119::Parser.new(f)
    v = J2119::NodeValidator.new(p)
    explore(v, p)
  end


  def explore(v, p)
    # just gonna run through the state machine spec exercising each
    #  constraint
    obj = {:StartAt=>'pass'}
    run_test(v, p, obj, 1)
    
    obj.delete(:StartAt)
    obj[:States] = {}
    run_test(v, p, obj, 1)

    obj[:StartAt] = 'pass'
    run_test(v, p, obj, 0)

    obj[:Version] = 3
    run_test(v, p, obj, 1)

    obj[:Version] = "1.0"
    obj[:Comment] = true
    run_test(v, p, obj, 1)

    obj[:Comment] = 'Hi'
    states = obj[:States]
    states[:pass] = {}
    run_test(v, p, obj, 2)

    # Pass state & general
    pass = states[:pass]
    pass[:Next] = 's1'
    pass[:Type] = 'Pass'

    run_test(v, p, obj, 0)

    pass[:Type] = 'flibber'
    run_test(v, p, obj, 1)

    pass[:Type] = 'Pass'
    pass[:Comment] = 23.5
    run_test(v, p, obj, 1)

    pass[:Type] = 'Pass'
    pass[:Comment] = ''
    run_test(v, p, obj, 0)

    pass[:Type] = 'Pass'
    pass[:Comment] = ''
    pass[:End] = 11
    run_test(v, p, obj, 1)
    
    pass[:End] = true
    run_test(v, p, obj, -1)
    
    pass.delete :Next
    run_test(v, p, obj, 0)

    pass[:InputPath] = 1
    pass[:ResultPath] = 2
    run_test(v, p, obj, 2)
    pass[:InputPath] = 'foo'
    pass[:ResultPath] = 'bar'
    run_test(v, p, obj, 2)

    # Fail state
    fail = { 'Type' => 'Fail', :Cause => 'a', :Error => 'b' }
    pass.delete(:InputPath)
    pass.delete(:ResultPath)
    states['fail'] = fail
    # puts JSON.pretty_generate(obj)
    run_test(v, p, obj, 0)
    fail[:InputPath] = fail[:ResultPath] = 'foo'
    run_test(v, p, obj, 4)
    fail.delete(:InputPath)
    fail.delete(:ResultPath)
    run_test(v, p, obj, 0)

    fail[:Cause] = false
    run_test(v, p, obj, 1)
    fail[:Cause] = 'ouch'
    run_test(v, p, obj, 0)

    # Task state
    task = { :Type => 'Task', :Resource => 'a:b', :Next => 'fail' }
    states['task'] = task
    run_test(v, p, obj, 0)

    task[:End] = 'foo'
    run_test(v, p, obj, 1)
    
    task[:End] = true
    task.delete :Next
    run_test(v, p, obj, 0)
    
    task[:Resource] = 11
    run_test(v, p, obj, 1)
    task[:Resource] = 'not a uri'
    run_test(v, p, obj, 1)

    task[:Resource] = 'foo:bar'
    task[:TimeoutSeconds] = 'x'
    task[:HeartbeatSeconds] = 3.9
    run_test(v, p, obj, -1)

    task[:TimeoutSeconds] = -2
    task[:HeartbeatSeconds] = 0
    run_test(v, p, obj, -1)
    
    task[:TimeoutSeconds] = 33
    task[:HeartbeatSeconds] = 44
    run_test(v, p, obj, 0)
    
    task[:Retry] = 1
    run_test(v, p, obj, 1)

    task[:Retry] = [ 1 ]
    run_test(v, p, obj, 1)

    task[:Retry] = [ { :MaxAttempts => 0 }, { :BackoffRate => 1.5 } ]
    run_test(v, p, obj, 2)

    task[:Retry] = [ {:ErrorEquals=> 1}, {:ErrorEquals=> true} ]
    run_test(v, p, obj, 2)
    
    task[:Retry] = [ {:ErrorEquals=> [ 1 ]}, {:ErrorEquals=> [ true ] } ]
    run_test(v, p, obj, 2)
    
    task[:Retry] = [ {:ErrorEquals=> [ 'foo' ]}, {:ErrorEquals=> [ 'bar' ] } ]
    run_test(v, p, obj, 0)

    rt = {
      :ErrorEquals => [ 'foo' ],
      :IntervalSeconds => 'bar',
      :MaxAttempts => true,
      :BackoffRate => {}
    }
    task[:Retry] = [ rt ]
    run_test(v, p, obj, 3)

    rt[:IntervalSeconds] = 0
    rt[:MaxAttempts] = -1
    rt[:BackoffRate] = 0.9
    run_test(v, p, obj, 3)

    rt[:IntervalSeconds] = 5
    rt[:MaxAttempts] = 99999999
    rt[:BackoffRate] = 1.1
    run_test(v, p, obj, 1)

    rt[:MaxAttempts] = 99999998
    run_test(v, p, obj, 0)

    catch = { :ErrorEquals=> [ 'foo' ], :Next => 'n' }
    task[:Catch] = [ catch ]
    run_test(v, p, obj, 0)

    catch.delete :Next
    run_test(v, p, obj, 1)

    catch[:Next] = true
    run_test(v, p, obj, 1)
    
    catch[:Next] = 't'
    catch.delete :ErrorEquals
    run_test(v, p, obj, 1)
    
    catch[:ErrorEquals] = []
    run_test(v, p, obj, 0)
    
    catch[:ErrorEquals] = [ 3 ]
    run_test(v, p, obj, 1)
    
    catch[:ErrorEquals] = [ 'x' ]

    # Choice state
    choice = {
      :Type => 'Choice',
      :Choices => [
        {
          :Next => 'z',
          :Variable => '$.a.b',
          :StringLessThan => 'xx'
        }
      ],
      :Default => 'x'
    }

    states.delete 'task'
    states.delete 'fail'
    obj[:States] = states
    
    states['choice'] = choice
    run_test(v, p, obj, 0)

    choice[:Next] = 'a'
    run_test(v, p, obj, 1)
    choice.delete :Next
    choice[:End] = true
    run_test(v, p, obj, 1)
    choice.delete :End

    choices = choice[:Choices]
    choice[:Choices] = []
    run_test(v, p, obj, 1)

    choice[:Choices] = [ 1, "2" ]
    run_test(v, p, obj, 2)
    choices << { :Next => 'y', :Variable => '$.c.d', :NumericEquals => 5 }
    choice[:Choices] = choices
    run_test(v, p, obj, 0)

    nester = { :And => 'foo' }
    choices = [ nester ]
    choice[:Choices] = choices
    run_test(v, p, obj, 2)
    # puts JSON.pretty_generate obj

    nester['Next'] = 'x'
    run_test(v, p, obj, 1)
    nester[:And] = []
    run_test(v, p, obj, 1)

    nester[:And] = [
        {
          :Variable => '$.a.b',
          :StringLessThan => 'xx'
        },
        {
          :Variable => '$.c.d',
          :NumericEquals => 12
        },
        {
          :Variable => '$.e.f',
          :BooleanEquals => false
        }
    ]
    run_test(v, p, obj, 0)

    # data types
    bad = [
      { :Variable => '$.a', :Next => 'b', :StringEquals => 1 },
      { :Variable => '$.a', :Next => 'b', :StringLessThan => true },
      { :Variable => '$.a', :Next => 'b', :StringGreaterThan => 11.5 },
      { :Variable => '$.a', :Next => 'b', :StringLessThanEquals => 0 },
      { :Variable => '$.a', :Next => 'b', :StringGreaterThanEquals => false },
      { :Variable => '$.a', :Next => 'b', :NumericEquals => 'a' },
      { :Variable => '$.a', :Next => 'b', :NumericLessThan => true },
      { :Variable => '$.a', :Next => 'b', :NumericGreaterThan => [3,4] },
      { :Variable => '$.a', :Next => 'b', :NumericLessThanEquals => { } },
      { :Variable => '$.a', :Next => 'b', :NumericGreaterThanEquals => 'bar' },
      { :Variable => '$.a', :Next => 'b', :BooleanEquals => 3 },
      { :Variable => '$.a', :Next => 'b', :TimestampEquals => 'a' },
      { :Variable => '$.a', :Next => 'b', :TimestampLessThan => 3 },
      { :Variable => '$.a', :Next => 'b', :TimestampGreaterThan => true },
      { :Variable => '$.a', :Next => 'b', :TimestampLessThanEquals => false },
      { :Variable => '$.a', :Next => 'b', :TimestampGreaterThanEquals => 3 }
    ]
    good = [
      { :Variable => '$.a', :Next => 'b', :StringEquals => 'foo' },
      { :Variable => '$.a', :Next => 'b', :StringLessThan => 'bar' },
      { :Variable => '$.a', :Next => 'b', :StringGreaterThan => 'baz' },
      { :Variable => '$.a', :Next => 'b', :StringLessThanEquals => 'foo' },
      { :Variable => '$.a', :Next => 'b', :StringGreaterThanEquals => 'bar' },
      { :Variable => '$.a', :Next => 'b', :NumericEquals => 11 },
      { :Variable => '$.a', :Next => 'b', :NumericLessThan => 12 },
      { :Variable => '$.a', :Next => 'b', :NumericGreaterThan => 13 },
      { :Variable => '$.a', :Next => 'b', :NumericLessThanEquals => 14.3 },
      { :Variable => '$.a', :Next => 'b', :NumericGreaterThanEquals => 14.4 },
      { :Variable => '$.a', :Next => 'b', :BooleanEquals => false },
      { :Variable => '$.a', :Next => 'b', :TimestampEquals => "2016-03-14T01:59:00Z" },
      { :Variable => '$.a', :Next => 'b', :TimestampLessThan => "2016-03-14T01:59:00Z" },
      { :Variable => '$.a', :Next => 'b', :TimestampGreaterThan => "2016-03-14T01:59:00Z" },
      { :Variable => '$.a', :Next => 'b', :TimestampLessThanEquals => "2016-03-14T01:59:00Z" },
      { :Variable => '$.a', :Next => 'b', :TimestampGreaterThanEquals => "2016-03-14T01:59:00Z" }
    ]

    bad.each do |comp|
      choice[:Choices] = [ comp ]
      run_test(v, p, obj, 1)
    end

    good.each do |comp|
      choice[:Choices] = [ comp ]
      run_test(v, p, obj, 0)
    end
    
    # nesting
    choice[:Choices] =  [
      {
        :Not => {
          :Variable => "$.type",
          :StringEquals => "Private"
        },
        :Next => "Public"
      },
      {
        :And => [
          {
            :Variable => "$.value",
            :NumericGreaterThanEquals => 20
          },
          {
            :Variable => "$.value",
            :NumericLessThan => 30
          }
        ],
        :Next => "ValueInTwenties"
      }
    ]
    run_test(v, p, obj, 0)

    choice[:Choices] =  [
      {
        :Not => {
          :Variable => false,
          :StringEquals => "Private"
        },
        :Next => "Public"
      }
    ]
    run_test(v, p, obj, 1)

    choice[:Choices] =  [
      {
        :And => [
          {
            :Variable => "$.value",
            :NumericGreaterThanEquals => 20
          },
          {
            :Variable => "$.value",
            :NumericLessThan => 'foo'
          }
        ],
        :Next => "ValueInTwenties"
      }
    ]
    run_test(v, p, obj, 1)
    
    choice[:Choices] =  [
      {
        :And => [
          {
            :Variable => "$.value",
            :NumericGreaterThanEquals => 20,
            :Next => "x"
          },
          {
            :Variable => "$.value",
            :NumericLessThan => 44
          }
        ],
        :Next => "ValueInTwenties"
      }
    ]
    run_test(v, p, obj, 1)

    choice[:Choices] =  [
      {
        :And => [
          {
            :Variable => "$.value",
            :NumericGreaterThanEquals => 20,
            :And => true
          },
          {
            :Variable => "$.value",
            :NumericLessThan => 44
          }
        ],
        :Next => "ValueInTwenties"
      }
    ]
    run_test(v, p, obj, 2)
    states.delete 'choice'

    # Wait state
    states['wait'] = {
      :Type => 'Wait',
      :Next => 'z',
      :Seconds => 5
    }
    run_test(v, p, obj, 0)

    states['wait'][:Seconds] = 't'
    run_test(v, p, obj, 1)
    states['wait'].delete :Seconds
    states['wait'][:SecondsPath] = 12
    run_test(v, p, obj, 1)
    states['wait'].delete :SecondsPath
    states['wait'][:Timestamp] = false
    run_test(v, p, obj, 1)
    states['wait'].delete :Timestamp
    states['wait'][:TimestampPath] = 33
    run_test(v, p, obj, 1)
    states['wait'].delete :TimestampPath
    states['wait'][:Timestamp] = "2016-03-14T01:59:00Z"
    run_test(v, p, obj, 0)

    states['wait'] = {
      :Type => 'Wait',
      :Next => 'z',
      :Seconds => 5,
      :SecondsPath => '$.x'
    }
    run_test(v, p, obj, 1)
    states.delete 'wait'

    para = {
      :Type => 'Parallel',
      :End => true,
      :Branches => [
        {
          :StartAt => 'p1',
          :States => {
            'p1' => {
              :Type => 'Pass',
              :End => true
            }
          }
        }
      ]
    }
    states['parallel'] = para
    run_test(v, p, obj, 0)

    para[:Branches][0][:StartAt] = true
    run_test(v, p, obj, 1)

    para.delete :Branches
    run_test(v, p, obj, 1)

    para[:Branches] = 3
    run_test(v, p, obj, 1)

    para[:Branches] = []
    run_test(v, p, obj, 0)
    
    para[:Branches] = [ 3 ]
    run_test(v, p, obj, 1)

    para[:Branches] = [ { } ]
    run_test(v, p, obj, 2)

    para[:Branches] =[
      {
        :StartAt => 'p1',
        :States => {
          'p1' => {
            :Type => 'foo',
            :End => true
          }
        }
      }
    ]

    run_test(v, p, obj, 2)
    para[:Branches] =[
      {
        :foo => 1,
        :StartAt => 'p1',
        :States => {
          'p1' => {
            :Type => 'Pass',
            :End => true
          }
        }
      }
    ]
    run_test(v, p, obj, 1)
  end

  def dump(problems)
    puts "\n"
    problems.each {|problem| puts "P: #{problem}"}
  end

  def run_test(v, p, obj, wanted_error_count, wanted_strings = [])
    problems = []
    json = JSON.parse(JSON.generate(obj))
    v.validate_node(json, p.root, [ p.root ], problems)
    if wanted_error_count != -1
      expect(problems.size).to eq(wanted_error_count)
    end
    problems
  end

end
