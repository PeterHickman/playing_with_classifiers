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
# Features: (3) petal_length, petal_width, sepal_length
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

The names appear in the same order as the columns of data and the second value can be either `float`, `integer`, `boolean`, `string` or `target`. These are less statements of what the data is than how the data will be handled. This is a work in progress and things will change

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

What has happened here is the data, `data/iris.csv`,  has been split into two new datasets. One for training that contains 70% of the original data and another dataset that contains the remaining 30% to test the function that was created. Both datasets have the same proportions of target features

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

Each has it's own strengths

## How many features?

For a moment lets go back to the iris dataset we first looked at. In the comments of the Gini function that was created we have `Features: petal_length, petal_width, sepal_length`. The dataset itself contains four features but `sepal_width` was not necessary to build a classifier with a 95% success rate. Not all features are necessary. It's part of the process, if we knew what features we would need before we went and measured things then we could just write out the rules by hand

You collect as much data as you can and let the classifier find out what we actually need

Lets take this further, the `blood_samples_dataset_balanced.csv` dataset has 24 features. Lets see how that works out

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
[GINI] Elapsed 1.513557

[ID3] Input training.csv
[ID3] Output fred_id3.rb
[ID3] Elapsed 0.12932

[TEST] fred_gini.rb has a 100.0000% success rate
[TEST] fred_id3.rb has a 100.0000% success rate
```

The Gini classifier used only 12 features, the ID3 classifier used only **one**!!! Both scored 100%

The ID3 classifier is overfitting. The glucose values are given at such an absurd precision that each outcome can be unambiguously associated with a target classification. Never blindly trust what comes out of the system, question everything. Perhaps rounding the data to 2 decimal places would be the way to approach this

So what can we do when we have lots of features. Well one technique is to pick a subset of the features at random and check them out. Generally the rule is if you have `X` features the subset size should be `sqrt(X)`. So for 24 features we will take a subset of 5

"Which features should I pick?" you ask. All of them. All combinations of 5 features from the original 24. All 42,504 of them in this case. Thats going to be a lot of work. No problem we have a program and copious amounts of tea to drink

```
$  ❯ ./forest --source data/blood_samples_dataset_balanced.csv --split .7 --number 5
[FOREST] forest_training.csv has 24 features
[FOREST] There are 42504 combinations of 5 features
[FOREST] 1/42504 Using glucose, cholesterol, hemoglobin, platelets, white_blood_cells
[FOREST] 2/42504 Using glucose, cholesterol, hemoglobin, platelets, red_blood_cells
[FOREST] 3/42504 Using glucose, cholesterol, hemoglobin, platelets, hematocrit
[FOREST] 4/42504 Using glucose, cholesterol, hemoglobin, platelets, mean_corpuscular_volume
...
[FOREST] 42499/42504 Using alt, ast, heart_rate, creatinine, troponin
[FOREST] 42500/42504 Using alt, ast, heart_rate, creatinine, c_reactive_protein
[FOREST] 42501/42504 Using alt, ast, heart_rate, troponin, c_reactive_protein
[FOREST] 42502/42504 Using alt, ast, creatinine, troponin, c_reactive_protein
[FOREST] 42503/42504 Using alt, heart_rate, creatinine, troponin, c_reactive_protein
[FOREST] 42504/42504 Using ast, heart_rate, creatinine, troponin, c_reactive_protein
[FOREST] fred_1_id3.rb   100.0000% success rate
[FOREST] fred_1_gini.rb  100.0000% success rate
[FOREST] fred_2_id3.rb   100.0000% success rate
[FOREST] fred_2_gini.rb  100.0000% success rate
[FOREST] fred_3_id3.rb   100.0000% success rate
[FOREST] fred_3_gini.rb  100.0000% success rate
[FOREST] fred_4_id3.rb   100.0000% success rate
[FOREST] fred_4_gini.rb  100.0000% success rate
[FOREST] fred_5_id3.rb   100.0000% success rate
...
[FOREST] fred_42501_gini.rb 100.0000% success rate
[FOREST] fred_42502_id3.rb 100.0000% success rate
[FOREST] fred_42502_gini.rb 100.0000% success rate
[FOREST] fred_42503_id3.rb 100.0000% success rate
[FOREST] fred_42503_gini.rb 100.0000% success rate
[FOREST] fred_42504_id3.rb 100.0000% success rate
[FOREST] fred_42504_gini.rb 100.0000% success rate
```

I lied, I actually went to bed and let this run. The results are written to `report.csv` and both ID3 and Gini scored 100% for all combinations of 5 features. Good to know that we only need 5 of the 24 features to make a diagnosis. Except for ID3. Once again it fixated on the absurd precision of the features and only used 1 of the features

## Other version

In the `other_version` directory is a version of the ID3 classifier that I found on the interwebs. I cannot find it again so sorry for the original author for not naming them. But it is interesting in that the data is uses is not the csv based columnar dataset we are using. It just lists the known features

```
no,dirty,showing teeth,hair raised,barking
yes,growling,showing teeth,dirty,barking
no,collar,showing teeth,dirty,barking
no,barking,growling,clean,collar
yes,growling,hair raised,barking
no,hair raised,collar,clean,barking
no,collar,clean,growling,barking
no,barking
yes,showing teeth,dirty,barking,hair raised
no,dirty,collar,barking,showing teeth
yes,barking,hair raised,dirty,showing teeth
```

It can be turned into csv based data but it shows you that there are other approaches

