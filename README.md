# Playing with classifiers

## What are classifiers?

I'm thinking of an animal and you have 20 questions to try and identify the animal. Classifiers in AI (also known a decision trees) is a technique that takes a list of all the animals and looks for the best questions to ask to find out what the animal is

The classic classifier example is the Iris dataset. This is a list of measurements from three species of irises. The classifier algorithm will spit out a series of questions that will quickly classify any new data. For example...

```bash
$ ./classify --input data/iris.csv --output fred.rb --method gini
[GINI] Input data/iris.csv
[GINI] Output fred.rb
[GINI] Elapsed 0.004061
```

The output is in `fred.rb` and is the Ruby code that will return the classification

```ruby
# Created: 2025-12-21 14:48:40 +0000
# Rows: 150
# Columns: petal_length, petal_width, sepal_length
# Classifier: Gini
# Elapsed: 0.00376 seconds
#
def fred(data)
  if data['petal_length'] < 2.45 then
    return 'setosa'
  else
    if data['petal_length'] < 4.75 then
      if data['petal_width'] < 1.65 then
        return 'versicolor'
      else
        return 'virginica'
      end
    else
      if data['petal_width'] < 1.75 then
        if data['petal_length'] < 4.95 then
          return 'versicolor'
        else
          if data['petal_width'] < 1.55 then
            return 'virginica'
          else
            if data['sepal_length'] < 6.95 then
              return 'versicolor'
            else
              return 'virginica'
            end
          end
        end
      else
        if data['petal_length'] < 4.85 then
          if data['sepal_length'] < 5.95 then
            return 'versicolor'
          else
            return 'virginica'
          end
        else
          return 'virginica'
        end
      end
    end
  end
end
```

So we have a function called `fred` that takes a hash of values and return the name of the species. You no longer have to drag the whole of the classifier codebase around when you want to classify something. Feed the code into a lint tool such as `rubocop` and it will shrink even more

There are a couple of methods available `gini` and `id3`. `id3` is the o.g. of the classifier algorithms and is good when the feature values need to be exact. `gini` handles values on a scale rather than as discrete values

Compare the output of each on the iris dataset to see the differences. `id3` has it's place but I tend to default to `gini`

## Input file format

The `data` directory contains some sample datasets. They are essentially csv files but you can have comments and blank lines. Also the column headers are replace with a new syntax

```
@sepal_length float
@sepal_width float
@petal_length float
@petal_width float
@species target
```

The names appear in the same order as the columns of data and the second value can be either `float`, `integer`, `string` or `target`. These are less statements of what the data is than how the data will be handled. This is a work in progress and things will change

The last column is the target, the one that we will be output when trying to classify something. For the time being it has to be the last one. This will, hopefully, change

In some examples you might see numbers being used to represent something such as gender, `0 = male`, `1 = female`, `2 = unknown`. The problem here is that the classifiers see numbers as being numeric rather than symbols. Age, for example, makes sense as a number. `18 < 32` means something when the numbers represent ages. `0 < 2` means nothing when it translates to `male < unknown`

Other classifiers use numbers for everything because numbers are simpler for the computer to handle especially when you have a _lot_ of data. We can keep things more relatable with strings for such data

## TODO

1. Remove the hardcoded `TARGET` value from the classifies and have the dataset return the target column
2. Make sure that the target column can be anywhere other than the last column
