# Datasets

These are the datasets that I used to test how things work. Some sets show how things **don't** work and function more as warnings than examples. Anyhow what makes a (potentially) good dataset. Well the number of rows is a good start, too few and we are overfitting, the rules we generate become nothing more than a different way to write the original data

But larger dataset is no guarantee that it is a better than a smaller dataset. The second condition is number of unique classifications. In the abalone dataset we have 4,177 rows and 27 unique classifications. Some occur hundreds of times, some only once. Which means for several outcomes they will only occur only in the training data or the testing data. This is why the success is so poor for both classification methods. More data could probably improve this

High success scores are also a cause for concern. In `blood samples dataset balanced` the values in the data are are at such an absurd precision that the ID3 classifier is essentially mapped the values of the `glucose` feature to the target classification. Even rounding the data down to two decimal places only added 1 feature to map the solution

I am not saying you _have_ to use a lot of features but when a solution can be found using only 1 feature out of 25 you should be wary

|Name|Rows|Unique Values|Gini|ID3|
|---|--:|--:|--:|--:|
|abalone|4,177|28|19.5670%|6.7362%|
|banknotes|1,372|2|99.0268%|3.4063%|
|blood samples dataset balanced|2,351|5|100.0000%|100.0000%|
|breast cancer|569|2|95.8824%|5.2941%|
|crop recommendation|2,200|22|99.2424%|0.0000%|
|diabetes prediction dataset|100,000|2|94.9600%|80.3333%|
|diabetes|768|2|68.6957%|24.7826%|
|diamond buckets|6,000|19|83.8997%|72.7577%|
|diamond|6,000|4,821|1.8664%|1.9701%|
|heart statlog cleveland hungary final|1,190|2|84.8315%|47.4719%|
|iris|150|3|93.3333%|75.5556%|
|play tennis|14|2|66.6667%|0.0000%|
|seeds dataset|210|3|84.1270%|6.3492%|
|simple weather|14|2|33.3333%|100.0000%|
|weather classification data|13,200|4|91.0101%|28.6616%|
|weather forecast data|2,500|2|99.3324%|0.0000%|
|wine|178|3|92.3077%|38.4615%|
