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

  # Just a hash to remember constraints
  class RoleConstraints
    def initialize
      @constraints = {}
    end
    
    def add(role, constraint)
      @constraints[role] ||= []
      @constraints[role] << constraint
    end
    
    def get_constraints(role)
      @constraints[role] || []
    end
  end

end
