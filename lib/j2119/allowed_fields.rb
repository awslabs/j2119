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

# The States language is draconian/must-understand; no fields may appear which
#  aren't explicitly blessed by a MUST/MAY clause
module J2119

  class AllowedFields

    def initialize
      @allowed = {}
      @any = []
    end

    def set_allowed(role, child)
      @allowed[role] ||= []
      @allowed[role] << child
    end

    def set_any(role)
      @any << role
    end

    def allowed?(roles, child)
      any?(roles) || roles.any? do |role|
        @allowed[role] && @allowed[role].include?(child)
      end
    end

    def any?(roles)
      roles.any? do |role|
        @any.include?(role)
      end
    end
  end
end
