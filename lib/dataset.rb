# frozen_string_literal: true

require 'set'

class DataSet
  NUMERIC = 'numeric'
  CATAGORICAL = 'catagorical'
  TARGET = 'target'

  attr_reader :target, :rows

  def initialize(columns = {}, indexed = {}, target = nil)
    @columns = columns.dup
    @indexed = indexed.dup
    @target = target.dup

    @rows = []
  end

  def from_file(filename)
    File.open(filename, 'r').each do |line|
      line.chomp!

      next if line == ''
      next if line.start_with?('#')

      if line.start_with?('@')
        name, type, other = line[1..].split(/\s+/)
        column(name, type, other)
      else
        add(parse_row(line))
      end
    end
  end

  def add(row)
    @rows << row.dup
  end

  def targets
    ci = @columns[@target][:index]

    @rows.map { |row| row[ci] }.uniq
  end

  def target_counts
    ci = @columns[@target][:index]

    h = Hash.new(0)
    @rows.each do |row|
      h[row[ci]] += 1
    end

    h
  end

  def size
    @rows.size
  end

  def columns
    @columns.keys.reject { |c| c == @target }
  end

  def column_type(name)
    @columns[name][:type]
  end

  def column_index(name)
    @columns[name][:index]
  end

  def delete_columns(columns)
    columns.each do |name|
      delete_column(name)
      @columns.delete(name)
    end
  end

  def keep_columns(columns)
    delete_columns(self.columns - columns)
  end

  def rows_as_hash
    l = []

    @rows.each do |row|
      l << Hash[@columns.map { |c| c[0] }.zip(row)]
    end

    l
  end

  def gaps(name)
    if @columns[name][:type] == NUMERIC
      sparse_gaps(name)
    else
      values(name)
    end
  end

  def split(name, value)
    left = DataSet.new(@columns, @indexed, @target)
    right = DataSet.new(@columns, @indexed, @target)

    index = @columns[name][:index]
    if @columns[name][:type] == NUMERIC
      @rows.each do |row|
        if row[index] < value
          left.add(row)
        else
          right.add(row)
        end
      end
    else
      @rows.each do |row|
        if row[index] == value
          left.add(row)
        else
          right.add(row)
        end
      end
    end

    [left, right]
  end

  def extract(name, value)
    left = DataSet.new(@columns, @indexed, @target)

    index = @columns[name][:index]

    @rows.each do |row|
      left.add(row) if row[index] == value
    end

    left
  end

  def extract_rows(rows)
    ds = DataSet.new(@columns, @indexed, @target)

    rows.each do |i|
      ds.add(@rows[i])
    end

    ds
  end

  def select(rows)
    left = DataSet.new(@columns, @indexed, @target)

    ##
    # This is cumbersome because we will allow multiple
    # copies of the same row
    ##
    rows.each do |row_number|
      left.add(@rows[row_number])
    end

    left
  end

  def count(value)
    ##
    # Count the number of targets that have the value 'value'
    ##
    ci = @columns[@target][:index]
    @rows.select { |row| row[ci] == value }.size
  end

  def values(name)
    ci = @columns[name][:index]

    @rows.map { |row| row[ci] }.uniq
  end

  def parse_row(line)
    row = []

    index = 0
    line.split(',').each do |item|
      case @columns[@indexed[index]][:type]
      when NUMERIC
        row << if @columns[@indexed[index]][:other].nil?
                 item.to_f
               else
                 item.to_f.round(@columns[@indexed[index]][:other])
               end
      when CATAGORICAL
        row << item
      when TARGET
        row << item
      end

      index += 1
    end

    row
  end

  def save(filename)
    f = File.new(filename, 'w')

    columns.each do |name|
      f.puts "@#{name} #{@columns[name][:type]} #{@columns[name][:other]}"
    end
    f.puts "@#{@target} target"
    f.puts
    @rows.each do |row|
      f.puts row.join(',')
    end

    f.close
  end

  def self.split_pure_random(ds, split)
    x = {}

    tr_count = (ds.size * split).to_i
    te_count = ds.size - tr_count

    train_rows = tr_count.times.map { rand(ds.size) }
    test_rows = te_count.times.map { rand(ds.size) }

    train_rows.each do |row|
      target = ds.rows[row][-1]
      x[target] = { total: 0, train: 0, test: 0 } unless x.key?(target)
      x[target][:total] += 1
      x[target][:train] += 1
    end

    test_rows.each do |row|
      target = ds.rows[row][-1]
      x[target] = { total: 0, train: 0, test: 0 } unless x.key?(target)
      x[target][:total] += 1
      x[target][:test] += 1
    end

    [x, train_rows, test_rows]
  end

  def self.split_pure_balanced(ds, split)
    x = {}

    train_rows = []
    test_rows = []

    y = {}
    ds.targets.each do |t|
      y[t] = []
    end

    ds.rows.each_with_index do |row, i|
      t = row[-1]
      y[t] << i
    end

    y.each do |t, rows|
      tr_count = (rows.size * split).to_i
      te_count = rows.size - tr_count

      tr_count.times do
        train_rows << rows.sample
      end

      te_count.times do
        test_rows << rows.sample
      end
    end

    train_rows.each do |row|
      target = ds.rows[row][-1]
      x[target] = { total: 0, train: 0, test: 0 } unless x.key?(target)
      x[target][:total] += 1
      x[target][:train] += 1
    end

    test_rows.each do |row|
      target = ds.rows[row][-1]
      x[target] = { total: 0, train: 0, test: 0 } unless x.key?(target)
      x[target][:total] += 1
      x[target][:test] += 1
    end

    [x, train_rows, test_rows]
  end

  def self.split_unique_random(ds, split)
    n = (split * ds.size).to_i
    test_rows, train_rows = pick_n((0...ds.size).to_a, n)

    x = {}

    train_rows.each do |row|
      target = ds.rows[row][-1]
      x[target] = { total: 0, train: 0, test: 0 } unless x.key?(target)
      x[target][:total] += 1
      x[target][:train] += 1
    end

    test_rows.each do |row|
      target = ds.rows[row][-1]
      x[target] = { total: 0, train: 0, test: 0 } unless x.key?(target)
      x[target][:total] += 1
      x[target][:test] += 1
    end

    [x, train_rows, test_rows]
  end

  def self.split_unique_balanced(ds, split)
    x = {}

    train_rows = []
    test_rows = []

    ds.targets.each do |t|
      x[t] = { total: ds.count(t), test: 0, train: 0, rows: [] }
    end

    target_index = ds.column_index(ds.target)
    ds.rows.each_with_index do |row, i|
      x[row[target_index]][:rows] << i
    end

    m = 1.0 - split
    x.each do |t, v|
      x[t][:test] = [1, (v[:total] * m).to_i].max
      x[t][:train] = v[:total] - x[t][:test]
    end

    x.each_value do |v|
      a, b = pick_n(v[:rows], v[:test])
      train_rows += a
      test_rows += b
    end

    [x, train_rows, test_rows]
  end

  def self.create_training_and_test(filename, split, split_method, report = false)
    ds = DataSet.new
    ds.from_file(filename)

    x = {}
    train_rows = []
    test_rows = []

    case split_method
    when 'pure_balanced'
      x, train_rows, test_rows = split_pure_balanced(ds, split)
    when 'unique_balanced'
      x, train_rows, test_rows = split_unique_balanced(ds, split)
    when 'pure_random'
      x, train_rows, test_rows = split_pure_random(ds, split)
    when 'unique_random'
      x, train_rows, test_rows = split_unique_random(ds, split)
    else
      raise "Unknown split method [#{split_method}]"
    end

    train_ds = ds.extract_rows(train_rows)
    test_ds = ds.extract_rows(test_rows)

    if report
      puts "The data set contains #{ds.size} rows"
      puts "The target for classification is the [#{ds.target}] column"
      puts "There are #{ds.targets.size} unique values for #{ds.target}"
      puts "There are #{x.size} #{ds.target} values in the split data"
      puts "Split using the #{split_method} method"
      puts

      puts "Targets              :   total :   train :    test"
      puts "---------------------+---------+---------+--------"
      x.each do |t, v|
        puts format("%-20s : %7d : %7d : %7d", t, v[:total], v[:train], v[:test])
      end

      puts
      puts "The test dataset has #{test_ds.size} rows and is written to testing.csv"
      puts "The training dataset has #{train_ds.size} rows and is written to training.csv"
    end

    [train_ds, test_ds]
  end

  def self.pick_n(list, number)
    r = []

    number.times do
      i = rand(list.size)
      r << list[i]
      list.delete_at(i)
    end

    [list, r]
  end

  private

  def delete_column(name)
    index = @columns[name][:index]

    ##
    # Remove the column from the data
    ##
    @rows.each do |row|
      row.delete_at(index)
    end

    ##
    # Adjust the indexes
    ##
    new_indexed = {}
    @indexed.each do |i, n|
      if i < index
        new_indexed[i] = n
      elsif i > index
        new_indexed[i - 1] = n
      end
    end
    @indexed = new_indexed

    @columns.each_value do |data|
      data[:index] -= 1 if data[:index] > index
    end
  end

  def sparse_gaps(name)
    ##
    # Remember there might be no gap!
    ##

    ci = @columns[name][:index]
    ti = @columns[@target][:index]

    x = {}
    @rows.each do |row|
      v = row[ci]
      x[v] = Set.new unless x.key?(v)
      x[v] << row[ti]
    end

    gaps = []

    prev_value = nil
    prev_target = nil

    x.keys.sort.each do |v|
      gaps << prev_value + ((v - prev_value) / 2.0) if !prev_target.nil? && (prev_target != x[v])

      prev_value = v
      prev_target = x[v]
    end

    gaps
  end

  def column(name, type, other)
    raise "Column called [#{name}] already defined" if @columns.key?(name)

    if type == TARGET
      raise "Target already defined as [#{@target}]" unless @target.nil?

      @target = name
    end

    if type == NUMERIC
      ##
      # Allow us to define the rounding on numerics
      ##
      other = other.to_i unless other.nil?
    elsif other
      raise "Other defined on #{type} for #{name}. Only available for numeric"
    end

    index = @columns.size
    @columns[name] = { type: type, index: index, other: other }
    @indexed[index] = name
  end
end
