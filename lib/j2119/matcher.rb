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

  # Does the heavy lifting of parsing j2119 files to extract all
  #  the assertions, making egregious use of regular expressions.
  #
  # This is the kind of thing I actively discourage when other
  #  programmers suggest it.  If I were a real grown-up I'd
  #  implement a proper lexer and bullet-proof parser.
  #
  class Matcher

    # crutch for RE debugging
    attr_reader :constraint_match, :roledef_match, :only_one_match

    # actual exports
    attr_reader :role_matcher, :eachof_match
    
    MUST = '(?<modal>MUST|MAY|MUST NOT)'
    TYPES = [
      'array',
      'object',
      'string',
      'boolean',
      'numeric',
      'integer',
      'float',
      'timestamp',
      'JSONPath',
      'referencePath',
      'URI'
    ]
    
    RELATIONS = [
      '', 'equal to', 'greater than', 'less than',
      'greater than or equal to', 'less than or equal to'
    ].join('|')
    RELATION = "((?<relation>#{RELATIONS})\\s+)"

    S = '"[^"]*"' # string
    V = '\S+'     # non-string value: number, true, false, null
    RELATIONAL = "#{RELATION}(?<target>#{S}|#{V})"

    CHILD_ROLE = ';\s+((its\s+(?<child_type>value))|' +
                 'each\s+(?<child_type>field|element))' +
                 '\s+is\s+an?\s+' +
                 '"(?<child_role>[^"]+)"'

    @@initialized = false

    # constants that need help from oxford
    def constants
      if !@@initialized
        @@initialized = true

        @@strings = Oxford.re(S, :capture_name => 'strings')
        enum = "one\s+of\s+#{@@strings}"

        @@predicate = "(#{RELATIONAL}|#{enum})"
      end
    end

    def reconstruct
      make_type_regex

      # conditional clause
      excluded_roles = "not\\s+" +
                       Oxford.re(@role_matcher,
                                 :capture_name => 'excluded',
                                 :use_article => true) +
                       "\\s+"
      conditional = "which\\s+is\\s+" +
                    excluded_roles

      # regex for matching constraint lines
      c_start = '^An?\s+' +
                "(?<role>#{@role_matcher})" + '\s+' +
                "(#{conditional})?" +
                MUST + '\s+have\s+an?\s+'
      field_list = "one\\s+of\\s+" +
                   Oxford.re('"[^"]+"', :capture_name => 'field_list')
      c_match = c_start + 
                "((?<type>#{@type_regex})\\s+)?" +
                "field\\s+named\\s+" +
                "((\"(?<field_name>[^\"]+)\")|(#{field_list}))" +
                '(\s+whose\s+value\s+MUST\s+be\s+' + @@predicate + ')?' +
                '(' + CHILD_ROLE + ')?' +
                '\.'

      # regexp for matching lines of the form
      #  "An X MUST have only one of "Y", "Z", and "W".
      #  There's a pattern here, building a separate regex rather than
      #  adding more complexity to @constraint_matcher.  Any further
      #  additions should be done this way, and
      #  TODO: Break @constraint_matcher into a bunch of smaller patterns
      #  like this.
      oo_start = '^An?\s+' +
                "(?<role>#{@role_matcher})" + '\s+' +
                 MUST + '\s+have\s+only\s+'
      oo_field_list = "one\\s+of\\s+" +
                      Oxford.re('"[^"]+"',
                                :capture_name => 'field_list',
                                :connector => 'and')
      oo_match = oo_start + oo_field_list

      # regex for matching role-def lines
      val_match = "whose\\s+\"(?<fieldtomatch>[^\"]+)\"" +
                  "\\s+field's\\s+value\\s+is\\s+" +
                  "(?<valtomatch>(\"[^\"]*\")|([^\"\\s]\\S+))\\s+"
      with_a_match = "with\\s+an?\\s+\"(?<with_a_field>[^\"]+)\"\\s+field\\s"

      rd_match = '^An?\s+' +
                 "(?<role>#{@role_matcher})" + '\s+' +
                 "((?<val_match_present>#{val_match})|(#{with_a_match}))?" +
                 "is\\s+an?\\s+" +
                 "\"(?<newrole>[^\"]*)\"\\.\\s*$"
      @roledef_match = Regexp.new(rd_match)

      @constraint_start = Regexp.new(c_start)
      @constraint_match = Regexp.new(c_match)

      @only_one_start = Regexp.new(oo_start)
      @only_one_match = Regexp.new(oo_match)
                       
      eo_match = "^Each\\s+of\\s" +
                 Oxford.re(@role_matcher,
                           :capture_name => 'each_of',
                           :use_article => true,
                           :connector => 'and') +
                 "\\s+(?<trailer>.*)$"

      @eachof_match = Regexp.new(eo_match)
    end

    def initialize(root)
      constants
      @roles = []
      add_role root
      reconstruct
    end
    
    def add_role(role)
      @roles << role
      @role_matcher = @roles.join('|')
      reconstruct
    end

    def self.tokenize_strings(s)
      # should be a way to do this with capture groups but I'm not smart enough
      strings = []
      r = Regexp.new '^[^"]*"([^"]*)"'
      while s =~ r
        strings << $1
        s = $'
      end
      strings
    end

    def tokenize_values(vals)
      vals.gsub(',', ' ').gsub('or', ' ').split(/\s+/)
    end
    
    def make_type_regex
      
      # add modified numeric types
      types = TYPES.clone
      number_types = [ 'float', 'integer', 'numeric' ]
      number_modifiers = [ 'positive', 'negative', 'nonnegative' ]
      number_types.each do |number_type|
        number_modifiers.each do |number_modifier|
          types << "#{number_modifier}-#{number_type}"
        end
      end
      
      # add array types
      array_types = types.map { |t| "#{t}-array" }
      types |= array_types
      nonempty_array_types = array_types.map { |t| "nonempty-#{t}" }
      types |= nonempty_array_types
      nullable_types = types.map { |t| "nullable-#{t}" }
      types |= nullable_types
      @type_regex = types.join('|')
    end

    def is_role_def_line(line)
      line =~ %r{is\s+an?\s+"[^"]*"\.\s*$}
    end

    def build_role_def(line)
      build(@roledef_match, line)
    end

    def build(re, line)
      data = {}
      match = re.match(line)
      match.names.each do |name|
        data[name] = match[name]
      end
      data
    end

    def build_only_one(line)
      build(@only_one_match, line)
    end

    def is_constraint_line(line)
      line =~ @constraint_start
    end

    def is_only_one_match_line(line)
      line =~ @only_one_start
    end

    def build_constraint(line)
      build(@constraint_match, line)
    end

  end


end
