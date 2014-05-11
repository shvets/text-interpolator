# Text Interpolator - Simple library for interpolation of variables inside the text.

## Introduction

You have few options in ruby for variables interpolation:

- interpolation inside the string:

```ruby
var1 = 'some value 1'
var2 = 'some value 2'

result = "We have var1: #{var1} and var2: #{var2}."

puts result # We have var1: some value 1 and var2: some value 2.
```

- interpolation inside file (with embedded ruby -  erb):

```ruby
# some_template.erb

We have var1: <%= var1 %> and var2:  <%= var2%>.

# test.rb

require 'erb'

var1 = 'some value 1'
var2 = 'some value 2'

template = ERB.new(File.read("some_template.erb"))

result = template.result(binding)

puts result # We have var1: some value 1 and var2: some value 2.
```

This library can be used for **interpolation inside file with string syntax**.

In order to achieve it library uses this ruby trick:

```ruby
env = {var1: 'some value 1', var2: 'some value 2'}

template = "We have var1: %{var1} and var2: %{var2}."

result = template % env

puts result # We have var1: some value 1 and var2: some value 2.
```

## Usage

It's straightforward:

```ruby
# some_template.txt

We have var1: #{var1} and var2:  #{var2}.
We have var3: #{settings.var3} and var4:  #{settings.var4}.

# test.rb

require 'text_interpolator'

env = {
  var1: 'some value 1',
  var2: 'some value 2',
  settings: {
    var3: 'some value 3',
    var4: 'some value 4'
  }
}

template = File.read("some_template.txt")

text_interpolator = TextInterpolator.new

result = text_interpolator.interpolate template, env

puts result # We have var1: some value 1 and var2: some value 2.
            # We have var3: some value 3 and var4: some value 4.
```