class Gini
  attr_reader :elapsed

  TARGET = -1

  def initialize(ds)
    @ds = ds

    @elapsed = nil
  end

  def walk
    t = Time.now
    x = walk_tree(@ds, 0)
    @elapsed = Time.now - t
    x
  end

  def report(name, list)
    t = []

    t << "# Created: #{Time.now}"
    t << "# Rows: #{@ds.size}"
    t << "# Columns: #{@ds.columns.join(', ')}"
    t << '# Classifier: Gini'
    t << "# Elapsed: #{@elapsed} seconds"
    t << '#'
    t << "def #{name}(data)"
    t << report_r(list, 1)
    t << 'end'

    t.join("\n")
  end

  private

  def report_r(list, depth)
    sp = ' ' * depth * 2

    root, left, right = list

    t = []

    t << "#{sp}#{root}"

    unless left.nil?
      t << if left.is_a? Array
             report_r(left, depth + 1)
           else
             "#{sp}  #{left}"
           end

      t << "#{sp}else"

      t << if right.is_a? Array
             report_r(right, depth + 1)
           else
             "#{sp}  #{right}"
           end

      t << "#{sp}end"
    end

    t.join("\n")
  end

  def walk_tree(ds, depth)
    best_name, best_value, best_left, best_right = best_split(ds)

    return "return '#{ds.targets.join(', ')}'" if best_name.nil?

    root = ds.column_type(best_name) == 'symbol' ? "if data['#{best_name}'] == '#{best_value}' then" : "if data['#{best_name}'] < #{best_value} then"

    left = best_left.targets.size == 1 ? "return '#{best_left.targets.first}'" : walk_tree(best_left, depth + 1)
    right = best_right.targets.size == 1 ? "return '#{best_right.targets.first}'" : walk_tree(best_right, depth + 1)

    [root, left, right]
  end

  def gini_index(lds, rds, targets)
    # count all samples at split point
    n_instances = (lds.size + rds.size).to_f

    gini = 0.0
    [lds, rds].each do |ds|
      size = ds.size

      next if size.zero?

      score = 0.0
      targets.each do |target|
        x = ds.rows.select { |row| row[TARGET] == target }.size.to_f / size
        score += x * x
      end
      gini += (1.0 - score) * (size / n_instances)
    end

    gini
  end

  def best_split(ds)
    best_name = nil
    best_value = nil
    best_left = nil
    best_right = nil
    best_gini = nil

    ds.columns.each do |name|
      ds.gaps(name).each do |value|
        l, r = ds.split(name, value)

        next unless l.targets.any?
        next unless r.targets.any?

        g = 1.0 - gini_index(l, r, ds.targets)

        if best_name.nil?
          best_name = name
          best_value = value
          best_left = l
          best_right = r
          best_gini = g
        elsif g > best_gini
          best_name = name
          best_value = value
          best_left = l
          best_right = r
          best_gini = g
        end
      end
    end

    [best_name, best_value, best_left, best_right]
  end
end
