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

  # to be applied to a role/constraint combo, so the constraint is applied
  #  conditionally
  #
  # These all respond_to
  # constraint_applies(node, roles)
  #  - node is the JSON node being checked
  #  - roles is the roles the node currently has

  class RoleNotPresentCondition

    def initialize(exclude_roles)
      @excluded_roles = exclude_roles
    end

    def to_s
      "excluded roles: #{@excluded_roles}"
    end

    def constraint_applies(node, roles)
      (roles & @excluded_roles).empty?
    end
    
  end

end
