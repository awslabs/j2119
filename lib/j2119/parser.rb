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

  class Parser

    ROOT = Regexp.new('This\s+document\s+specifies\s+' +
                      'a\s+JSON\s+object\s+called\s+an?\s+"([^"]+)"\.')

    attr_reader :root

    # for debugging
    attr_reader :finder

    def initialize(j2119_file)

      have_root = false
      @failed = false
      @constraints = RoleConstraints.new
      @finder = RoleFinder.new
      @allowed_fields = AllowedFields.new
      
      j2119_file.each_line do |line|
        if line =~ ROOT
          if have_root
            fail "Only one root declaration"
          else
            @root = $1
            @matcher = Matcher.new(root)
            @assigner =
              Assigner.new(@constraints, @finder, @matcher, @allowed_fields)
            have_root = true
          end
        else
          if !have_root
            fail "Root declaration must come first"
          else
            proc_line(line)
          end
        end
      end
      if @failed
        raise "Could not create parser"
      end
    end

    def proc_line(line)
      if @matcher.is_constraint_line(line)
        @assigner.assign_constraints @matcher.build_constraint(line)
      elsif @matcher.is_only_one_match_line(line)
        @assigner.assign_only_one_of(@matcher.build_only_one(line))
      elsif line =~ /^Each of a/
        eaches_line = @matcher.eachof_match.match(line)
        eaches = Oxford.break_role_list(@matcher, eaches_line['each_of'])
        eaches.each do |each|
          proc_line("A #{each} #{eaches_line['trailer']}")
        end
      elsif @matcher.is_role_def_line(line)
        @assigner.assign_roles @matcher.build_role_def(line)
      else
        fail "Unrecognized line: #{line}"
      end
    end

    def fail(message)
      @failed = true
      STDERR.puts message
    end

    def find_more_roles(node, roles)
      @finder.find_more_roles(node, roles)
    end

    def find_grandchild_roles(roles, name)
      @finder.find_grandchild_roles(roles, name)
    end

    def find_child_roles(roles, name)
      @finder.find_child_roles(roles, name)
    end

    def get_constraints(role)
      @constraints.get_constraints(role)
    end

    def field_allowed?(roles, child)
      @allowed_fields.allowed?(roles, child)
    end
  end
end
