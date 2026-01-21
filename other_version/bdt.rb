# frozen_string_literal: true

class Array
  L2 = Math.log(2)

  def info_content
    total = sum
    sum do |elt|
      if elt.positive?
        p = elt / total
        -p * (Math.log(p) / L2)
      else
        0.0
      end
    end
  end

  def sum
    total = 0.0
    if block_given?
      each { |e| total += yield(e) }
    else
      each { |e| total += e }
    end
    total
  end
end

class BDT
end

class BDT_internal < BDT
  def initialize(question, children)
    @question = question
    @yes, @no = children
  end

  def classify
    print "#{@question}? "
    return @yes.classify if $stdin.gets =~ /^[Yy]/

    @no.classify
  end

  def to_s(logic = '', indent = '')
    "#{indent}#{logic}if #{@question}\n#{@yes.to_s('then ', "#{indent}  ")}#{@no.to_s('else ', "#{indent}  ")}"
  end

  alias inspect to_s
end

class BDT_leaf < BDT
  def initialize(c)
    @classification = c
  end

  def classify
    @classification
  end

  def to_s(logic = '', indent = '')
    "#{indent}#{logic}#{@classification}\n"
  end

  alias inspect to_s
end

class BDT_sample
  def initialize(c, atr)
    @classification = c
    @attributes = atr
  end

  attr_reader :classification, :attributes
end

class BDT_set
  def initialize(source)
    if source.is_a?(String)
      @samples = File.readlines(source).map do |line|
        tokens = line.split(',').map(&:strip)
        classification = tokens.delete_at(0)
        BDT_sample.new(classification, tokens)
      end
      @samples.delete_if { |s| s.classification =~ /(^$)|(^#)/ }
    else
      @samples = source
    end
  end

  def make_tree
    best = attributes.min do |a1, a2|
      expected_info_content(split(a1)) <=> expected_info_content(split(a2))
    end

    if expected_info_content(split(best)) < expected_info_content([self])
      BDT_internal.new(best, split(best).collect(&:make_tree))
    else
      BDT_leaf.new(classification_totals.max { |x, y| x[1] <=> y[1] }.first)
    end
  end

  def attributes
    @samples.map(&:attributes).flatten.uniq
  end

  def classification_totals
    h = Hash.new(0)
    @samples.each { |s| h[s.classification] += 1 }
    h
  end

  def expected_info_content(sets)
    num_samples = sets.sum { |s| s.samples.size }
    sets.sum do |s|
      v = s.classification_totals.values
      v.info_content * v.sum / num_samples
    end
  end

  def split(atr)
    with = []
    without = []
    @samples.each do |s|
      if s.attributes.include?(atr)
        with.push s
      else
        without.push s
      end
    end
    [BDT_set.new(with), BDT_set.new(without)]
  end

  def inspect
    @samples.map { |s| "#{s.classification}: #{s.attributes.sort.join(',')}" }.join("\n")
  end

  attr_reader :samples
end
