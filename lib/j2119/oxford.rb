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

  # We have to recognize lots of lists like so:
  #  X
  #  X or X
  #  X, X, or X
  # Examples:
  # one of "Foo", "Bar", or "Baz"
  # a Token1, a Token2, or a Token3
  class Oxford
    BASIC = "(?<CAPTURE>X((((,\\s+X)+,)?)?\\s+or\\s+X)?)"

    def self.re(particle, opts = {})
      has_capture, inter, has_connector, last = BASIC.split 'X'
      has_connector.gsub!('or', opts[:connector]) if opts[:connector]
      if opts[:use_article]
        particle = "an?\\s+(#{particle})"
      else
        particle = "(#{particle})"
      end
      if opts[:capture_name]
        has_capture.gsub!('CAPTURE', opts[:capture_name])
      else
        has_capture.gsub!('?<CAPTURE>', '')
      end
      [ has_capture, inter, has_connector, last].join(particle)
    end

    def self.break_string_list list
      pieces = []
      re = Regexp.compile "^[^\"]*\"([^\"]*)\""
      while list =~ re
        pieces << $1
        list = $'
      end
      pieces
    end

    def self.break_role_list(matcher, list)
      pieces = []
      re = Regexp.compile "^an?\\s+(#{matcher.role_matcher})(,\\s+)?"
      while list =~ re
        pieces << $1
        list = $'
      end
      if list =~ /^\s*(and|or)\s+an?\s+(#{matcher.role_matcher})/
        pieces << $2
      end
      pieces
    end
    
  end

end
