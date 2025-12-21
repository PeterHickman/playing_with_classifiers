# Playing with classifiers

## What are classifiers?

I'm thinking of an animal and you have 20 questions to try and identify the animal I am thinking of. Classifiers in AI (also known a decision trees) is a technique that takes a list of all the animals and looks for the best questions to ask to find out what the animal is

The classic classifier example is the Iris dataset. This is a list of measurements from three species of irises. The classifier algorithm will spit out a series of questions that will quickly classify any new data. For example...

```bash
$ ./classify --input data/iris.csv --output fred.rb --method gini
[GINI] Input data/iris.csv
[GINI] Output fred.rb
[GINI] Elapsed 0.004061
```

The output is in `fred.rb` and is the Ruby code that will return the classification

```ruby
# Created: 2025-12-21 11:47:21 +0000
# Rows: 150
# Columns: sepal_length, sepal_width, petal_length, petal_width
# Classifier: Gini
# Elapsed: 0.004061 seconds
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

1. Explain it
2. No always using numbers

## TODO

1. Remove the hardcoded `TARGET` value from the classifies and have the dataset return the target column. Also make sure that the target column can be anywhere other than the last column
