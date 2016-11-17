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
require 'j2119/assigner'
require 'j2119/conditional'
require 'j2119/constraints'
require 'j2119/deduce'
require 'j2119/matcher'
require 'j2119/node_validator'
require 'j2119/oxford'
require 'j2119/parser'
require 'j2119/role_constraints'
require 'j2119/role_finder'
require 'j2119/allowed_fields'
require 'j2119/json_path_checker'

module J2119

  class Validator

    attr_reader :parsed
    
    def initialize assertions_source
      assertions = File.open(assertions_source, "r")
      @parser = Parser.new assertions
    end

    def root
      @parser.root
    end

    def validate json_source
      # already parsed?
      if json_source.is_a?(Hash)
        @parsed = json_source
      else
        if json_source.respond_to?(:read)
          text = json_source.read
        elsif File.readable? json_source
          text = File.read json_source
        else
          text = json_source
        end
        begin
          @parsed = JSON.parse text
        rescue Exception => e
          return [ "Problem reading/parsing JSON: #{e.to_s}" ]
        end
      end
      
      problems = []
      validator = NodeValidator.new(@parser)
      validator.validate_node(@parsed,
                              @parser.root,
                              [ @parser.root ],
                              problems)
      problems
    end

    def to_s
      "J2119 validator for instances of \"#{@parser.root}\""
    end
  end
  
end
