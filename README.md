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

## Sounds good. Is it really though?

The thing is the function that it has created a function but how good is it? Good question. Well we have to do something different

```
$ ./wf data/iris.csv
The data set contains 150 rows
The target for classification is the [species] column

Targets              :   total :   train :    test
---------------------+---------+---------+--------
setosa               :      50 :      35 :      15
versicolor           :      50 :      35 :      15
virginica            :      50 :      35 :      15

The test dataset has 45 rows and is written to testing.csv
The training dataset has 105 rows and is written to training.csv

[GINI] Input training.csv
[GINI] Output fred_gini.rb
[GINI] Elapsed 0.002627

[ID3] Input training.csv
[ID3] Output fred_id3.rb
[ID3] Elapsed 0.001121

[TEST] fred_gini has a 95.5556% success rate
[TEST] fred_id3 has a 77.7778% success rate
```

What has happened here is the data, `data/iris.csv`,  has been split into two new datasets. One for training that contains 70% of the original data and another dataset that contains the remaining 30% to test the function that was created

For good measure, and because it's automated and takes no extra effort, we have built a `gini` and `id3` function and tested each against the test dataset. `gini` got 95% accuracy and `id3` got 77%. Not sure I would trust something that is only 77% accurate but 95% sounds good

But be cautious here, this was only trained on 105 rows. Thats not a lot of data. More data is better. Lets try again with another dataset

```
$ ./wf data/blood_samples_dataset_balanced.csv
The data set contains 2351 rows
The target for classification is the [disease] column

Targets              :   total :   train :    test
---------------------+---------+---------+--------
Healthy              :     556 :     390 :     166
Diabetes             :     540 :     378 :     162
Thalasse             :     509 :     357 :     152
Anemia               :     623 :     437 :     186
Thromboc             :     123 :      87 :      36

The test dataset has 702 rows and is written to testing.csv
The training dataset has 1649 rows and is written to training.csv

[GINI] Input training.csv
[GINI] Output fred_gini.rb
[GINI] Elapsed 1.770575

[ID3] Input training.csv
[ID3] Output fred_id3.rb
[ID3] Elapsed 0.132669

[TEST] fred_gini has a 100.0000% success rate
[TEST] fred_id3 has a 100.0000% success rate
```

Much more data and even 100% accuracy. But be aware the `Thromboc` classification was trained on only 87 rows. So perhaps a little caution here still

Finally another one

```
$ ./wf data/banknotes.csv
The data set contains 1372 rows
The target for classification is the [class] column

Targets              :   total :   train :    test
---------------------+---------+---------+--------
fake                 :     762 :     534 :     228
real                 :     610 :     427 :     183

The test dataset has 411 rows and is written to testing.csv
The training dataset has 961 rows and is written to training.csv

[GINI] Input training.csv
[GINI] Output fred_gini.rb
[GINI] Elapsed 0.47708

[ID3] Input training.csv
[ID3] Output fred_id3.rb
[ID3] Elapsed 0.184268

[TEST] fred_gini has a 98.5401% success rate
[TEST] fred_id3 has a 2.9197% success rate
```

Again `gini` is doing great but `id3` is worse than chance, much much much worse than chance. It's as if it is deliberately picking the wrong answers (perhaps I shouldn't anthropomorphise my code). `id3` did great with the blood test data but fails here

## TODO

1. Remove the hardcoded `TARGET` value from the classifiers
2. Make sure that the target column can be anywhere other than the last column
