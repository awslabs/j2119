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

  # This is about figuring out which roles apply to a node and
  #  potentially to its children in object and array valued fields
  #
  class RoleFinder

    # for debugging
    attr_reader :field_value_roles
    
    def initialize
      # roles of the form: If an object with role X has field Y which
      #  is an object, that object has role R
      @child_roles = {}

      # roles of the form: If an object with role X has field Y which
      #  is an object/array, the object-files/array-elements have role R
      @grandchild_roles = {}

      # roles of the form: If an object with role X has a field Y with
      #  value Z, it has role R
      # map[role][field_name][field_val] => child_role
      @field_value_roles = {}

      # roles of the form: If an object with role X has a field Y, then
      #  it has role R
      # map[role][field_name] => child_role
      @field_presence_roles = {}

      # roles of the form: A Foo is a Bar
      @is_a_roles = {}
    end

    def add_is_a_role(role, other_role)
      @is_a_roles[role] ||= []
      @is_a_roles[role] << other_role
    end

    def add_field_value_role(role, field_name, field_value, new_role)
      @field_value_roles[role] ||= {}
      @field_value_roles[role][field_name] ||= {}
      field_value = Deduce.value(field_value)
   
      @field_value_roles[role][field_name][field_value] = new_role
    end

    def add_field_presence_role(role, field_name, new_role)
      @field_presence_roles[role] ||= {}
      @field_presence_roles[role][field_name] = new_role
    end

    def add_child_role(role, field_name, child_role)
      @child_roles[role] ||= {}
      @child_roles[role][field_name] = child_role
    end

    def add_grandchild_role(role, field_name, child_role)
      @grandchild_roles[role] ||= {}
      @grandchild_roles[role][field_name] = child_role
    end

    # Consider a node which has one or more roles. It may have more
    #  roles based on the presence or value of child nodes. This method
    #  addes any such roles to the "roles" list
    #
    def find_more_roles(node, roles)

      # find roles depending on field values
      roles.each do |role|
        per_field_name = @field_value_roles[role]
        if per_field_name
          per_field_name.each do |field_name, value_roles|
            value_roles.each do |field_value, child_role|
              if field_value == node[field_name]
                roles << child_role
              end
            end
          end
        end
      end

      # find roles depending on field presence
      roles.each do |role|
        per_field_name = @field_presence_roles[role]
        if per_field_name
          per_field_name.each do |field_name, child_role|
            if node.key? field_name
              roles << child_role
            end
          end
        end
      end

      # is_a roles
      roles.each do |role|
        other_roles = @is_a_roles[role]
        if other_roles
          other_roles.each { |o| roles << o }
        end
      end
    end

    # A node has a role, and one of its fields might be object-valued
    #  and that value is given a role
    def find_child_roles(roles, field_name)
      newroles = []
      roles.each do |role|
        if @child_roles[role] && @child_roles[role][field_name]
          newroles << @child_roles[role][field_name]
        end
      end
      newroles
    end

    # A node has a role, and one of its field is an object or an
    #  array whose fields or elements are given a role
    #
    def find_grandchild_roles(roles, field_name)
      newroles = []
      roles.each do |role|
        if @grandchild_roles[role] && @grandchild_roles[role][field_name]
          newroles << @grandchild_roles[role][field_name]
        end
      end
      newroles
    end
    
  end

end
