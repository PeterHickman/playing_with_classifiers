#!/usr/bin/env ruby

require 'pp'

$LOAD_PATH << '.'

require 'bdt'

samples = BDT_set.new(ARGV[0])
tree = samples.make_tree

puts
puts '-----------------'
pp tree

puts "Answer: #{tree.classify}"
