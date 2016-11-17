# coding: utf-8
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

# Examines fields which are supposed to be JSONPath expressions or Reference
#  Paths, which are JSONPaths that are singular, i.e. don't produce array
#  results
#
module J2119

  INITIAL_NAME_CLASSES = [ 'Lu', 'Ll', 'Lt', 'Lm', 'Lo', 'Nl' ]
  NON_INITIAL_NAME_CLASSES = [ 'Mn', 'Mc', 'Nd', 'Pc' ]
  FOLLOWING_NAME_CLASSES = INITIAL_NAME_CLASSES | NON_INITIAL_NAME_CLASSES
  DOT_SEPARATOR = '\.\.?'
  
  class JSONPathChecker

    def self.classes_to_re classes
      re_classes = classes.map  {|x| "\\p{#{x}}" }
      "[#{re_classes.join('')}]"
    end

    @@name_re = classes_to_re(INITIAL_NAME_CLASSES) +
                classes_to_re(FOLLOWING_NAME_CLASSES) + '*'
    dot_step = DOT_SEPARATOR + '((' + @@name_re + ')|(\*))'
    rp_dot_step = DOT_SEPARATOR + @@name_re
    bracket_step = '\[' + "'" + @@name_re + "'" + '\]'
    rp_num_index = '\[\d+\]'
    num_index = '\[\d+(, *\d+)?\]'
    star_index = '\[\*\]'
    colon_index = '\[(-?\d+)?:(-?\d+)?\]'
    index = '((' + num_index + ')|(' + star_index + ')|(' + colon_index + '))'
    step = '((' + dot_step + ')|(' + bracket_step + '))' + '(' + index + ')?'
    rp_step = '((' + rp_dot_step + ')|(' + bracket_step + '))' + '(' + rp_num_index + ')?'
    path = '^\$' + '(' + step + ')+$'
    reference_path = '^\$' + '(' + rp_step + ')+$'
    @@path_re = Regexp.new(path)
    @@reference_path_re = Regexp.new(reference_path);

    def self.is_path?(s)
      s.is_a?(String) && @@path_re.match(s)
    end

    def self.is_reference_path?(s)
      s.is_a?(String) && @@reference_path_re.match(s)
    end
  end
end
