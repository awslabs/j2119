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

  class NodeValidator

    def initialize(parser)
      @parser = parser
    end

    def validate_node(node, path, roles, problems)

      if !node.is_a?(Hash)
        return
      end

      # may have more roles based on field presence/value etc
      @parser.find_more_roles(node, roles)

      # constraints are attached per-role
      # TODO - look through the constraints and if there is a
      #  "Field should not exist" constraint, then disable
      #  type and value checking constraints
      #
      roles.each do |role|
        @parser.get_constraints(role).each do |constraint|
          if constraint.applies(node, roles)
            constraint.check(node, path, problems)
          end
        end
      end

      # for each field
      node.each do |name, val|

        if !@parser.field_allowed?(roles, name)
          problems << "Field \"#{name}\" not allowed in #{path}"
        end

        # only recurse into children if they have roles
        child_roles = @parser.find_child_roles(roles, name)
        if !child_roles.empty?
          validate_node(val, "#{path}.#{name}", child_roles, problems)
        end

        # find inheritance-based roles for that field
        grandchild_roles = @parser.find_grandchild_roles(roles, name)
        if (!grandchild_roles.empty?) && (!@parser.allows_any?(grandchild_roles))
          # recurse into grandkids
          if val.is_a? Hash
            val.each do |child_name, child_val|
              validate_node(child_val, "#{path}.#{name}.#{child_name}",
                            grandchild_roles.clone, problems)
            end
          elsif val.is_a? Array
            i = 0
            val.each do |member|
              validate_node(member, "#{path}.#{name}[#{i}]",
                            grandchild_roles.clone, problems)
              i += 1
            end
          end
        end
      end
    end
  end
end
