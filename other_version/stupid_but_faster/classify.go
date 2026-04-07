package main

// Functions to implement
//
// 1. [DONE] Infomation about a dataset
// 2. [DONE] Split a dataset into training and testing
// 3. Classify with ID3
// 4. [DONE] Classify with Gini
// 5. [DONE] Measure accuracy of 3 and 4

import (
	"flag"
	"fmt"
	"log"

	ep "github.com/PeterHickman/expand_path"
	"github.com/PeterHickman/toolbox"

	"classify/dataset"
	"classify/gini"
	"classify/tree"
)

var function string
var source string
var training string
var testing string
var output string
var solution string
var number float64

func info(filename string) {
	ds := dataset.LoadFromFile(filename)

	fmt.Printf("The dataset contains %d rows and has %d columns\n", len(ds.Rows), len(ds.Columns))

	var unique_values []map[float64]int

	for range ds.Columns {
		unique_values = append(unique_values, map[float64]int{})
	}

	// Count the unique values
	var x float64

	for _, row := range ds.Rows {
		for i := range ds.Columns {
			x = row[i]

			_, ok := unique_values[i][x]
			if ok {
				unique_values[i][x]++
			} else {
				unique_values[i][x] = 1
			}
		}
	}

	for i, v := range ds.Columns {
		if v.Type == "numeric" {
			fmt.Printf("Column %d, %s, is of type %s with %d unique values\n", i+1, v.Name, v.Type, len(unique_values[i]))
		} else {
			fmt.Printf("Column %d, %s, is of type %s with %d symbols\n", i+1, v.Name, v.Type, len(v.Symbols))
			for j, c := range unique_values[i] {
				fmt.Printf("   %-20s : %d\n", v.Symbols[int(j)], c)
			}
		}
	}
}

func split(filename string, number float64, training string, testing string) {
	ds := dataset.LoadFromFile(filename)

	tr_ds := ds.CopyStructure()
	te_ds := ds.CopyStructure()

	// Group the row numbers by target

	x := make(map[float64][]float64)

	for i, row := range ds.Rows {
		j := float64(row[ds.TargetColumn])
		x[j] = append(x[j], float64(i))
	}

	m := 1.0 - number
	for _, rows := range x {
		testing_size := max(1, int(float64(len(rows))*m))
		testing_rows, training_rows := dataset.RandomSplitList(rows, testing_size)

		for _, v := range testing_rows {
			te_ds.Rows = append(te_ds.Rows, ds.Rows[int(v)])
		}

		for _, v := range training_rows {
			tr_ds.Rows = append(tr_ds.Rows, ds.Rows[int(v)])
		}
	}

	tr_ds.Save(training, fmt.Sprintf("Training dataset built from %s", filename))
	te_ds.Save(testing, fmt.Sprintf("Testing dataset built from %s", filename))
}

func with_gini(filename string, output string) {
	ds := dataset.LoadFromFile(filename)

	gini.Gini(ds, output)
}

func test_solution(filename string, solution string) {
	ds := dataset.LoadFromFile(filename)
	sol := tree.Load(solution)

	total := float64(ds.Size())
	correct := 0.0

	for i := range ds.Rows {
		r := sol.Walk(ds, i)
		if r {
			correct = correct + 1.0
		}
	}

	fmt.Printf("Solution in %s scored %f%% against %s\n", solution, (correct/total)*100.0, filename)
}

func dont_use_string(function string, option string, value string) {
	if value != "" {
		log.Fatalf("--%s is not compatible with --%s\n", option, function)
	}
}

func dont_use_float(function string, option string, value float64) {
	if value != -1.0 {
		log.Fatalf("--%s is not compatible with --%s\n", option, function)
	}
}

func init() {
	i := flag.Bool("info", false, "display information for dataset")
	x := flag.Bool("split", false, "split the dataset into training and testing")
	g := flag.Bool("classify", false, "generate a classifier")
	t := flag.Bool("test", false, "measure the success of a solution")

	s := flag.String("source", "", "the dataset to read")
	o := flag.String("output", "", "the solutiion as json")
	sol := flag.String("solution", "", "the solution to test")

	tr := flag.String("training", "", "save the training dataset to this")
	te := flag.String("testing", "", "save the testing dataset to this")
	f := flag.Float64("number", -1.0, "how much makes up the training dataset")

	flag.Parse()

	if *s == "" {
		log.Fatal("No dataset to read with --source")
	} else {
		source, _ = ep.ExpandPath(*s)
		if !toolbox.FileExists(source) {
			log.Fatalf("The file %s does not exist\n", source)
		}
	}

	// First check the actions

	if *i {
		if function != "" {
			log.Fatal("--info cannot be used in conjunction with other functions")
		} else {
			function = "info"
			dont_use_string(function, "training", *tr)
			dont_use_string(function, "testing", *te)
			dont_use_string(function, "solution", *sol)
			dont_use_string(function, "output", *o)
			dont_use_float(function, "number", *f)
		}
	}

	if *x {
		if function != "" {
			log.Fatalf("--split cannot be used in conjunction with other functions")
		} else {
			function = "split"
			if *tr == "" {
				log.Fatal("name the dataset to save the training portion to with --training")
			} else {
				training = *tr
			}
			if *te == "" {
				log.Fatal("name the dataset to save the testing portion to with --testing")
			} else {
				testing = *te
			}
			if testing == training {
				log.Fatal("The training and testing dataset files have the same name")
			}
			if *f == -1.0 {
				log.Fatal("the split between training and testing is given with --number")
			}
			if *f <= 0.0 || *f >= 1.0 {
				log.Fatal("the split between training and testing should be > 0.0 and < 1.0")
			} else {
				number = *f
			}
			dont_use_string(function, "solution", *sol)
			dont_use_string(function, "output", *o)
		}
	}

	if *g {
		if function != "" {
			log.Fatalf("--gini cannot be used in conjunction with other functions")
		} else {
			function = "gini"
			if *o == "" {
				log.Fatal("name the output file to write solution to with --output")
			} else {
				output = *o
			}
			dont_use_string(function, "training", *tr)
			dont_use_string(function, "testing", *te)
			dont_use_string(function, "solution", *sol)
			dont_use_float(function, "number", *f)
		}
	}

	if *t {
		if function != "" {
			log.Fatalf("--test cannot be used in conjunction with other functions")
		} else {
			function = "test"
			if *sol == "" {
				log.Fatal("name the solution test --solution")
			} else {
				solution = *sol
			}
			dont_use_string(function, "training", *tr)
			dont_use_string(function, "testing", *te)
			dont_use_string(function, "output", *o)
			dont_use_float(function, "number", *f)
		}
	}
}

func main() {
	switch function {
	case "info":
		info(source)
	case "split":
		split(source, number, training, testing)
	case "gini":
		with_gini(source, output)
	case "test":
		test_solution(source, solution)
	default:
		log.Fatal("No action selected")
	}
}
