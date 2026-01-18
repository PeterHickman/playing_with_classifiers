# frozen_string_literal: true

class Test
  def test(filename, function)
    ds = DataSet.new
    ds.from_file(filename)

    eval(File.read(function))

    fn = File.basename(function, '.rb')

    t = 0.0
    c = 0.0

    ds.rows_as_hash.each do |row|
      t += 1

      c += 1 if send(fn, row) == row[ds.target]
    end

    c / t * 100
  end
end
