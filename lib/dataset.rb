# frozen_string_literal: true

require 'set'

class DataSet
  attr_reader :target, :rows

  GAPS = %w[integer float].freeze

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

  def gaps(name)
    if GAPS.include? @columns[name][:type]
      sparse_gaps(name)
    else
      values(name)
    end
  end

  def split(name, value)
    left = DataSet.new(@columns, @indexed, @target)
    right = DataSet.new(@columns, @indexed, @target)

    index = @columns[name][:index]
    if GAPS.include? @columns[name][:type]
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
      when 'float'
        row << if @columns[@indexed[index]][:other].nil?
                 item.to_f
               else
                 item.to_f.round(@columns[@indexed[index]][:other])
               end
      when 'integer'
        row << item.to_i
      when 'symbol'
        row << item
      when 'target'
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

    if type == 'target'
      raise "Target already defined as [#{@target}]" unless @target.nil?

      @target = name
    end

    if type == 'float'
      ##
      # Allow us to define the rounding on floats
      ##
      other = other.to_i unless other.nil?
    elsif other
      raise "Other defined on #{type} for #{name}. Only available for float"
    end

    index = @columns.size
    @columns[name] = { type: type, index: index, other: other }
    @indexed[index] = name
  end
end
