# frozen_string_literal: true

require 'set'

class ID3
  attr_reader :elapsed

  TARGET = -1

  # The smallest realistic number. This is to stop us crashing on a zero where is can't be used
  EPS = 2.220446049250313e-16

  def initialize(ds)
    @ds = ds

    @elapsed = nil
    @used = Set.new
  end

  def walk
    t = Time.now
    x = build_tree(@ds)
    @elapsed = Time.now - t
    x
  end

  def report(name, tree)
    t = []
    r = report_tree(tree, @ds.target, 1)

    t << "# Created: #{Time.now}"
    t << "# Rows: #{@ds.size}"
    t << "# Columns: #{@used.to_a.join(', ')}"
    t << '# Classifier: ID3'
    t << '#'
    t << "def #{name}(data)"
    t << r
    t << 'end'

    t.join("\n")
  end

  private

  def dataset_entropy(ds)
    ##
    # Calculate the entropy of the whole dataset based on how
    # many distinct values there are for the target. The ideal
    # is 0 (there is only 1 target value in the dataset). The
    # value just keeps getting larger the more distinct target
    # values there are. The value itself is not of interest only
    # in that we can say "this dataset has less entropy than
    # that dataset", which is what we want
    ##
    entropy_node = 0

    ds.targets.each do |target|
      fraction = ds.count(target) / ds.size.to_f
      entropy_node += -fraction * Math.log2(fraction)
    end

    entropy_node
  end

  def columns_entropy(ds, name)
    attribute_entropy = {}
    attribute_totals = Hash.new(0)

    ds.values(name).each do |x|
      attribute_entropy[x] = {}
      ds.targets.each do |t|
        attribute_entropy[x][t] = 0
      end
    end

    ci = ds.column_index(name)
    ds.rows.each do |row|
      attribute_totals[row[ci]] += 1
      attribute_entropy[row[ci]][row[TARGET]] += 1
    end

    total_entropy = 0.0
    attribute_entropy.each do |a_name, v|
      feature_entropy = 0.0

      v.each_value do |num|
        fraction = num / (attribute_totals[a_name] + EPS)
        feature_entropy += -fraction * Math.log2(fraction + EPS)
      end

      fraction2 = attribute_totals[a_name] / ds.size.to_f
      total_entropy += -fraction2 * feature_entropy
    end

    total_entropy.abs
  end

  def find_winner(ds)
    winner_name = nil
    winner_value = nil

    de = dataset_entropy(ds)

    ds.columns.each do |name|
      ##
      # Information gain is a measure of the difference in entropy
      # between the original dataset and a potential split on a
      # particular column. Basically we are trying to find the new
      # dataset that has least entopy
      ##
      information_gain = de - columns_entropy(ds, name)

      if winner_name
        if information_gain > winner_value
          winner_name = name
          winner_value = information_gain
        end
      else
        winner_name = name
        winner_value = information_gain
      end
    end

    winner_name
  end

  def build_tree(ds, tree = nil)
    winner = find_winner(ds)

    tree = { winner => {} } if tree.nil?

    ds.values(winner).each do |value|
      nds = ds.extract(winner, value)
      value = "'#{value}'" if @ds.column_type(winner) == 'symbol'

      targets = nds.targets
      tree[winner][value] = if targets.size == 1
                              targets.first
                            else
                              build_tree(nds)
                            end
    end

    tree
  end

  def report_tree(tree, target, depth)
    variable = tree.keys.first

    sp = ' ' * depth * 2

    r = []

    first_line = true
    tree[variable].each do |(k, v)|
      if first_line
        r << "#{sp}if data['#{variable}'] == #{k} then"
        @used << variable
        first_line = false
      else
        r << "#{sp}elsif data['#{variable}'] == #{k} then"
        @used << variable
      end

      r << if v.is_a? String
             "#{sp}  return '#{v}'"
           else
             report_tree(v, target, depth + 1)
           end
    end
    r << "#{sp}end"

    r.join("\n")
  end
end
