# Playing with classifiers

## What are classifiers?

I'm thinking of an animal and you have 20 questions to try and identify the animal. Classifiers in AI (also known a decision trees) are a technique that takes a list of all the animals and looks for the best questions to ask to find out what the animal is

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
@sepal_length numeric
@sepal_width numeric
@petal_length numeric
@petal_width numeric
@species target
```

The names appear in the same order as the columns of data and the second value can be either `numeric `, `catagorical`, or `target`. These are less statements of what the data is than how the data will be handled

The last column is the target, the one that we will be output when trying to classify something. For the time being it has to be the last one. This will, hopefully, change

What is "numeric" data? Well think of things that can be measured as numbers, things like age, height, weight or blood pressure. They are measured in numbers and can be compared as numbers. It makes sense to say that someone's blood pressure is high compared to a base line. You can use a combination of height and weight to determine the level of obesity. Numeric data is measured in numbers and the data can be compared as numbers. Basically we can _rank_ numerical data by the value and it will make sense

What about eye colour? There is no way to measure the colour of an eye as a number and other than saying that blue eyes are not brown eyes we cannot rank eye colour. Thus eye colour is catagorical

Classifiers use numbers for everything because numbers are simpler for the computer to handle especially when you have a _lot_ of data. We can keep things more relatable with strings for such data

## Sounds good. Is it really though?

The thing is the function that it has created a function but how good is it? Good question. Well we have to do something different

```
$ ./wf pure_random data/iris.csv
The data set contains 150 rows
The target for classification is the [species] column
There are 3 unique values for species
There are 3 species values in the split data
Split using the pure_random method

Targets              :   total :   train :    test
---------------------+---------+---------+--------
virginica            :      46 :      35 :      11
versicolor           :      55 :      40 :      15
setosa               :      49 :      30 :      19

The test dataset has 45 rows and is written to testing.csv
The training dataset has 105 rows and is written to training.csv

[GINI] Input training.csv
[GINI] Output fred_gini.rb
[GINI] Elapsed 0.002345

[ID3] Input training.csv
[ID3] Output fred_id3.rb
[ID3] Elapsed 0.000893

[TEST] fred_gini.rb has a 100.0000% success rate
[TEST] fred_id3.rb has a 95.5556% success rate
```

What has happened here is the data, `data/iris.csv`,  has been split into two new datasets. One for training that contains 70% of the original data and another dataset that contains the remaining 30% to test the function that was created. There are four ways to split the data and we have used `pure_random` here. We will explain it in a later section

For good measure, and because it's automated and takes no extra effort, we have built a `gini` and `id3` function and tested each against the test dataset. `gini` got 100% accuracy and `id3` got 95%

But be cautious here, this was only trained on 150 rows. Thats not a lot of data. More data is better. Lets try again with another dataset

```
$ ./wf pure_random data/blood_samples_dataset_balanced.csv
The data set contains 2351 rows
The target for classification is the [disease] column
There are 5 unique values for disease
There are 5 disease values in the split data
Split using the pure_random method

Targets              :   total :   train :    test
---------------------+---------+---------+--------
Anemia               :     636 :     450 :     186
Thalasse             :     470 :     331 :     139
Thromboc             :     132 :      94 :      38
Diabetes             :     588 :     414 :     174
Healthy              :     525 :     356 :     169

The test dataset has 706 rows and is written to testing.csv
The training dataset has 1645 rows and is written to training.csv

[GINI] Input training.csv
[GINI] Output fred_gini.rb
[GINI] Elapsed 2.185256

[ID3] Input training.csv
[ID3] Output fred_id3.rb
[ID3] Elapsed 0.141209

[TEST] fred_gini.rb has a 100.0000% success rate
[TEST] fred_id3.rb has a 100.0000% success rate
```

Much more data and even 100% accuracy. But be aware the `Thromboc` classification was trained on only 94 rows. So perhaps a little caution here still

Finally another one

```
$ ./wf pure_random data/banknotes.csv
The data set contains 1372 rows
The target for classification is the [class] column
There are 2 unique values for class
There are 2 class values in the split data
Split using the pure_random method

Targets              :   total :   train :    test
---------------------+---------+---------+--------
fake                 :     747 :     508 :     239
real                 :     625 :     452 :     173

The test dataset has 412 rows and is written to testing.csv
The training dataset has 960 rows and is written to training.csv

[GINI] Input training.csv
[GINI] Output fred_gini.rb
[GINI] Elapsed 0.400103

[ID3] Input training.csv
[ID3] Output fred_id3.rb
[ID3] Elapsed 0.136165

[TEST] fred_gini.rb has a 98.3010% success rate
[TEST] fred_id3.rb has a 51.6990% success rate
```

Again `gini` is doing great but `id3` is only slightly better than chance

Each has it's own strengths

## Splitting the data

To generate a solution we need data to train it on. We also need data to test the solution on. So we take source data and split it into two parts, the training dataset and the testing dataset. I have a training dataset that is 70% of the size of the original data and 30% for the testing data

There are four methods to split the data available here

1. **pure_random** If we have an original dataset of 10,000 rows then we will create the training dataset by picking 7,000 rows from the original dataset and 3,000 rows for the testing. There are two features of this method. The training and test datasets will contain duplicate rows and as a result some rows will appear in both the training and testing datasets. Also targets can be under/over represented in their respective dataset compared to the original dataset, or even missing entirely
2. **unique_random** A variation of the above except this time each row from the original dataset will appear in either dataset. This avoid the problem of duplicates but does not address the balance of targets in the new datasets
3. **pure_balanced** In an attempt to address the balance issue each new dataset will have the same proportion of target rows in the new datasets as was in the original. It behaves like pure\_random but preserves the balance of targets and also has the same drawbacks as pure\_random too
4. **unique_balanced** Just as unique\_random sought to improve on pure\_random this method attempts to fix the target balance issue and improve on pure\_balanced

The method that seems to work the best is **pure_random**. Not completely intuitive given that it has the most detriments but I've tested this multiple times with the data here and it always comes out on top, perhaps only by a few percentage points, but consistently ahead of the others

Sometimes it does not pay to overthink. Just accept what the data tells you

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

The ID3 classifier is overfitting. The glucose values are given at such an absurd precision that any feature can be unambiguously associated with a target classification. Never blindly trust what comes out of the system, question everything. Rounding the data to 2 decimal places only adds one more feature for ID3 to use. ID3 is not suited to this dataset

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

In the `other_version` directory is a version of the ID3 classifier that I found on the interwebs. I cannot find it again so sorry to the original author for not naming them. But it is interesting in that the data is uses is not the csv based columnar dataset we are using. It just lists the known features

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

And then there is `stupid_but_faster`, a rewrite in Go that does not implement the ID3 classifier and outputs the solution as a tree encoded as JSON so that you can write your own scripts to do whatever you want with it. Either I will steal the last part (solution as JSON) or simple replace the Ruby version with the Go version. But to be honest Ruby runs fast enough at this point

