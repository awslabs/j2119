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

module J2119

  # Looks at the parsed form of the J2119 lines and figures out,
  #  by looking at which part of the regexes match, 
  #  the assignments of roles to nodes and constraints to roles
  class Assigner
    
    def initialize(role_constraints, role_finder, matcher, allowed_fields)
      @constraints = role_constraints
      @roles = role_finder
      @matcher = matcher
      @allowed_fields = allowed_fields
    end

    def assign_roles(assertion)
      if assertion['val_match_present']
        @roles.add_field_value_role(assertion['role'],
                                    assertion['fieldtomatch'],
                                    assertion['valtomatch'],
                                    assertion['newrole'])
        @matcher.add_role(assertion['newrole'])
      elsif assertion['with_a_field']
        @roles.add_field_presence_role(assertion['role'],
                                       assertion['with_a_field'],
                                       assertion['newrole'])
        @matcher.add_role(assertion['newrole'])
      else
        @roles.add_is_a_role(assertion['role'], assertion['newrole'])
        @matcher.add_role(assertion['newrole'])
      end
    end

    def assign_only_one_of(assertion)
      role = assertion['role']
      values = Oxford.break_string_list assertion['field_list']
      add_constraint(role, OnlyOneOfConstraint.new(values), nil)
    end
    
    def assign_constraints(assertion)
      role = assertion['role']
      modal = assertion['modal']
      type = assertion['type']
      field_name = assertion['field_name']
      field_list_string = assertion['field_list']
      relation = assertion['relation']
      target = assertion['target']
      strings = assertion['strings']
      child_type = assertion['child_type']
      vals = assertion['vals']

      # watch out for conditionals
      condition = nil
      if assertion['excluded']
        excluded_roles =
          Oxford.break_role_list(@matcher, assertion['excluded'])
        condition = RoleNotPresentCondition.new(excluded_roles)
      end
        
      if relation
        add_relation_constraint(role, field_name, relation, target,
                                condition)
      end
      
      if strings
        # of the form MUST have a <type> field named <field_name> whose value
        #  MUST be one of "a", "b", or "c"
        fields = Oxford.break_string_list strings
        add_constraint(role,
                       FieldValueConstraint.new(field_name, :enum => fields),
                       condition)
      end
      
      if type
        add_type_constraints(role, field_name, type, condition)
      end

      if field_list_string
        field_list = Oxford.break_string_list field_list_string
      end

      # register allowed fields
      if field_list_string
        field_list.each { |field| @allowed_fields.set_allowed(role, field) }
      elsif field_name
        @allowed_fields.set_allowed(role, field_name)
      end
      
      if modal == 'MUST'
        if field_list_string
          # Of the form MUST have a <type>? field named one of "a", "b", or "c".
          add_constraint(role, HasFieldConstraint.new(field_list), condition)
        else
          add_constraint(role, HasFieldConstraint.new(field_name), condition)
        end
      elsif modal == 'MUST NOT'
        add_constraint(role,
                       DoesNotHaveFieldConstraint.new(field_name), condition)
      end
      
      # there can be role defs there too
      if child_type
        @matcher.add_role assertion['child_role']
        if child_type == 'value'
          @roles.add_child_role(role, field_name, assertion['child_role'])
        elsif child_type == 'element' || child_type == 'field'
          @roles.add_grandchild_role(role, field_name, assertion['child_role'])
        end
      end


      # untyped field without a defined child role
      if field_name && !type && !child_type && modal != 'MUST NOT'
        @roles.add_grandchild_role(role, field_name, field_name)
        @allowed_fields.set_any(field_name)
      end
    end

    def add_constraint(role, constraint, condition)
      if condition
        constraint.add_condition condition
      end
      @constraints.add(role, constraint)
    end

    def add_relation_constraint(role, field, relation, target, condition)
      target = Deduce.value target
      case relation
      when 'equal to'
        params = { :equal => target }
      when 'greater than'
        params = { :floor => target }
      when 'less than'
        params = { :ceiling => target }
      when 'greater than or equal to'
        params = { :min => target }
      when 'less than or equal to'
        params = { :max => target }
      end
      add_constraint(role, FieldValueConstraint.new(field, params), condition)
    end

    def add_type_constraints(role, field, type, condition)

      is_array = (type =~ /-array/)
      is_nullable = (type =~ /nullable-/)
      type.split('-').each do |part|
        case part
        when 'object'
          add_constraint(role,
                         FieldTypeConstraint.new(field, :object,
                                                 is_array, is_nullable),
                         condition)
        when 'string'
          add_constraint(role,
                         FieldTypeConstraint.new(field, :string,
                                                 is_array, is_nullable),
                         condition)
        when 'URI'
          add_constraint(role,
                         FieldTypeConstraint.new(field, :URI,
                                                 is_array, is_nullable),
                         condition)
        when 'boolean'
          add_constraint(role,
                         FieldTypeConstraint.new(field, :boolean,
                                                 is_array, is_nullable),
                         condition)
        when 'numeric'
          add_constraint(role,
                         FieldTypeConstraint.new(field, :numeric,
                                                 is_array, is_nullable),
                         condition)
        when 'integer'
          add_constraint(role,
                         FieldTypeConstraint.new(field, :integer,
                                                 is_array, is_nullable),
                         condition)
        when 'float'
          add_constraint(role,
                         FieldTypeConstraint.new(field, :float,
                                                 is_array, is_nullable),
                         condition)
        when 'timestamp'
          add_constraint(role,
                         FieldTypeConstraint.new(field, :timestamp,
                                                 is_array, is_nullable),
                         condition)
        when 'JSONPath'
          add_constraint(role,
                         FieldTypeConstraint.new(field, :json_path,
                                                 is_array, is_nullable),
                         condition)
        when 'referencePath'
          add_constraint(role,
                         FieldTypeConstraint.new(field, :reference_path,
                                                 is_array, is_nullable),
                         condition)
        when 'positive'
          add_constraint(role,
                         FieldValueConstraint.new(field, :floor => 0),
                         condition)
        when 'nonnegative'
          add_constraint(role,
                         FieldValueConstraint.new(field, :min => 0),
                         condition)
        when 'negative'
          add_constraint(role,
                         FieldValueConstraint.new(field, :ceiling => 0),
                         is_array, condition)
        when 'nonempty'
          add_constraint(role, NonEmptyConstraint.new(field), condition)
        end
      end
    end

  end
end
