# j2119
A general-purpose validator generator that uses RFC2119-style assertions as input.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'j2119'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install j2119

## Usage

There is only one outward-facing class, Validator.

```ruby
validator = J2119::Validator.new(schema-file)
```

Where ```schema-file``` is the name of a file containing text in the J2119 
syntax described below. This yields a validator, which can be re-used,
and should be, since its construction is moderately expensive:

```ruby
problems = validator.validate(json_source)
```

```json_source``` is the text to be validated; it can be a string or an IO or
a filename, J2119 tries to do the right thing. ```validate``` returns a string
array containing messages describing any problems it found. If the array is
empty, then there were no problems.

There are also two utility methods. ```parsed``` returns the parsed form of
the ```json_source``` text.  The idea is that if you want to do any further
semantic validation, there's no reason to parse the JSON twice.

```root``` returns the root "role" in the J2119 schema, a string that is
useful in making user-friendly error messages.

## J2119 Syntax

J2119's operations are driven by a set of assertions containing the words
"MUST" and "MAY" used in the style found in IETF RFCs, and specified in
RFC 2119.  It is organized in lines, each terminated with a single full stop.
There are three formalisms, "roles", "types" and "constraints". For example:

```
A Message MUST have an object-array field named "Paragraphs"; each member is a "Paragraph".
```

In the above assertion, "Message" and "Paragraph" are roles, "string-array" is a
type; the whole line says that a JSON node with the role "Message" is required
to have a field named "Paragraphs" whose value is a JSON array containing only
object values.   It further says that when validating the object members of
the array, they are considered to have the role "Paragraph".

The first line of the J2119 schema must be of the following form:

```
This document specifies a JSON object called a "Message".
```

This gives the root object the role "Message". Descendant nodes can be given
roles based on their parentage (as in the first J2119 example above) and the
presence or value of certain fields, and nodes can have multiple roles
simultaneously.

The J2119 syntax was invented for the purpose of constructing a validator for
one specific JSON DSL, and at the time of writing of this document, there is
no claim that it is suitable as a general-purpose JSON schema facility.  At
this point, the best way to understand J2119 is by example.  In the
```data/``` directory of this gem there is a file ```AWL.j2119```, which
may be considered a complete worked example of how to specify a DSL.

## TODO

At the moment, the J2119 syntax is parsed via the brute-force application of
overly complex regular expressions.  It is in serious need of modularization,
a real modern parser architecture, and perhaps the application of some
natural-language processing techniques.

Aside from that, the framework of roles,
conditionals, and constraints is simple enough and performs at acceptable
speed.

## Contributing

Bug reports and pull requests are welcome on GitHub 

