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

require 'date'

module J2119

  # These all respond_to
  # check(node, path, problem)
  #  - node is the JSON node being checked
  #  - path is the current path, for reporting practices
  #  - problems is a list of problem reports
  # TODO: Add a "role" argument to enrich error reporting
  class Constraint
    def initialize
      @conditions = []
    end

    def add_condition(condition)
      @conditions << condition
    end

    def applies(node, role)
      return @conditions.empty? ||
        @conditions.map{|c| c.constraint_applies(node, role)}.any?
    end
  end

  # Verify that there is only one of a selection of fields
  #
  class OnlyOneOfConstraint < Constraint
    def initialize(fields)
      super()
      @fields = fields
    end

    def check(node, path, problems)
      if (@fields & node.keys).size > 1
        problems <<
          "#{path} may have only one of #{@fields}"
      end
    end
  end

  # Verify that array field is not empty
  #
  class NonEmptyConstraint < Constraint
    def initialize(name)
      super()
      @name = name
    end

    def to_s
      conds = (@conditions.empty?) ? '' : " #{@conditions.size} conditions"
      "<Array field #{@name} should not be empty#{conds}>"
    end
    
    def check(node, path, problems)
      if node[@name] && node[@name].is_a?(Array) && (node[@name].size == 0)
        problems <<
          "#{path}.#{@name} is empty, non-empty required"
      end
    end
  end

  # Verify node has the named field, or one of the named fields
  #
  class HasFieldConstraint < Constraint
    def initialize(name)
      super()
      if name.is_a?(String)
        @names = [ name ]
      else
        @names = name
      end
    end

    def to_s
      conds = (@conditions.empty?) ? '' : " #{@conditions.size} conditions"
      "<Field #{@names} should be present#{conds}>"
    end

    def check(node, path, problems)
      if (node.keys & @names).empty?
        if @names.size == 1
          problems <<
            "#{path} does not have required field \"#{@names[0]}\""
        else
          problems <<
            "#{path} does not have required field from #{@names}"
        end
      end
    end
  end

  # Verify node does not have the named field
  #
  class DoesNotHaveFieldConstraint < Constraint
    def initialize(name)
      super()
      @name = name
    end
    
    def to_s
      conds = (@conditions.empty?) ? '' : " #{@conditions.size} conditions"
      "<Field #{@name} should be absent#{conds}>"
    end

    def check(node, path, problems)
      if node[@name]
        problems <<
          "#{path} has forbidden field \"#{@name}\""
      end
    end
  end

  # Verify type of a field in a node
  #
  class FieldTypeConstraint < Constraint
    def initialize(name, type, is_array, is_nullable)
      super()
      @name = name
      @type = type
      @is_array = is_array
      @is_nullable = is_nullable
    end

    def to_s
      conds = (@conditions.empty?) ? '' : " #{@conditions.size} conditions"
      nullable = @is_nullable ? ' (nullable)' : ''
      "<Field #{@name} should be of type #{@type}#{conds}>#{nullable}"
    end

    def check(node, path, problems)

      # type-checking is orthogonal to existence checking
      return if !node.key?(@name)

      value = node[@name]
      path = "#{path}.#{@name}"

      if value == nil
        if !@is_nullable
          problems << "#{path} should be non-null"
        end
        return
      end

      if @is_array
        if value.is_a?(Array)
          i = 0
          value.each do |element|
            value_check(element, "#{path}[#{i}]", problems)
            i += 1
          end
        else
          report(path, value, 'an Array', problems)
        end
      else
        value_check(value, path, problems)
      end
    end
                 
    def value_check(value, path, problems)
      case @type
      when :object
        report(path, value, 'an Object', problems) if !value.is_a?(Hash)
      when :array
        report(path, value, 'an Array', problems) if !value.is_a?(Array)
      when :string
        report(path, value, 'a String', problems) if !value.is_a?(String)
      when :integer
        report(path, value, 'an Integer', problems) if !value.is_a?(Integer)
      when :float
        report(path, value, 'a Float', problems) if !value.is_a?(Float)
      when :boolean
        if value != true && value != false
          report(path, value, 'a Boolean', problems)
        end
      when :numeric
        report(path, value, 'numeric', problems) if !value.is_a?(Numeric)
      when :json_path
        report(path, value, 'a JSONPath', problems) if !JSONPathChecker.is_path?(value)
      when :reference_path
        report(path, value, 'a Reference Path', problems) if !JSONPathChecker.is_reference_path?(value)
      when :timestamp
        begin
          DateTime.rfc3339 value
        rescue
          report(path, value, 'an RFC3339 timestamp', problems)
        end
      when :URI
        if !(value.is_a?(String) && (value =~ /^[a-z]+:/))
          report(path, value, 'A URI', problems) 
        end
      end
      
    end

    def report(path, value, message, problems)
      if value.is_a?(String)
        value = '"' + value + '"'
      end
      problems << "#{path} is #{value} but should be #{message}"
    end
    
  end      

  # Verify constraints on values of a named field
  #
  class FieldValueConstraint < Constraint

    def initialize(name, params)
      super()
      @name = name
      @params = params
    end

    def to_s
      conds = (@conditions.empty?) ? '' : " #{@conditions.size} conditions"
      "<Field #{@name} has constraints #{@params}#{conds}>"
    end

    def check(node, path, problems)

      # value-checking is orthogonal to existence checking
      return if !node.key?(@name)

      value = node[@name]

      if @params[:enum]
        if !(@params[:enum].include?(value))
          problems <<
            "#{path}.#{@name} is \"#{value}\", " +
            "not one of the allowed values #{@params[:enum]}"
        end
        
        # if enum constraint are provided, others are ignored
        return
      end

      if @params[:equal]
        begin
          if value != @params[:equal]
            problems <<
              "#{path}.#{@name} is #{value} " +
              "but required value is #{@params[:equal]}"
          end
        rescue Exception
          # should be caught by type constraint
        end
      end
      if @params[:floor]
        begin
          if value <= @params[:floor]
            problems <<
              "#{path}.#{@name} is #{value} " +
              "but allowed floor is #{@params[:floor]}"
          end
        rescue Exception
          # should be caught by type constraint
        end
      end
      if @params[:min]
        begin
          if value < @params[:min]
            problems <<
              "#{path}.#{@name} is #{value} " +
              "but allowed minimum is #{@params[:min]}"
          end
        rescue Exception
          # should be caught by type constraint
        end
      end
      if @params[:ceiling]
        begin
          if value >= @params[:ceiling]
            problems <<
              "#{path}.#{@name} is #{value} " +
              "but allowed ceiling is #{@params[:ceiling]}"
          end
        rescue Exception
          # should be caught by type constraint
        end
      end
      if @params[:max]
        begin
          if value > @params[:max]
            problems <<
              "#{path}.#{@name} is #{value} " +
              "but allowed maximum is #{@params[:max]}"
          end
        rescue Exception
          # should be caught by type constraint
        end
      end
    end
  end

end


