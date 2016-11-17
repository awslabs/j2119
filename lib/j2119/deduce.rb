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

  class Deduce

    # we have to deduce the JSON value from they way they expressed it as
    #  text in the J2119 file.
    #
    def self.value(val)
      case val
      when /^"(.*)"$/
        $1
      when 'true'
        true
      when 'false'
        false
      when 'null'
        nil
      when /^\d+$/
        val.to_i
      else
        val.to_f
      end
        
    end
  end
end
