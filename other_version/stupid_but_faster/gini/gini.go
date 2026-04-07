package gini

import (
	"fmt"
	"strings"

	"classify/dataset"
	"classify/tree"
)

const max_depth = 100

func gini_index(lds dataset.Dataset, rds dataset.Dataset, targets []float64) float64 {
	// count all samples at split point
	n_instances := float64(lds.Size() + rds.Size())

	gini := 0.0

	if lds.Size() != 0 {
		size := float64(lds.Size())
		score := 0.0

		for _, target := range targets {
			x := count_rows_with_target(lds, target) / size
			score = score + (x * x)
		}

		gini = gini + (1.0-score)*(size/n_instances)
	}

	if rds.Size() != 0 {
		size := float64(rds.Size())
		score := 0.0

		for _, target := range targets {
			x := count_rows_with_target(rds, target) / size
			score = score + (x * x)
		}

		gini = gini + (1.0-score)*(size/n_instances)
	}

	return gini
}

func count_rows_with_target(ds dataset.Dataset, target float64) float64 {
	t := 0.0

	for _, row := range ds.Rows {
		if row[ds.TargetColumn] == target {
			t = t + 1.0
		}
	}

	return t
}

func best_split(ds dataset.Dataset) (string, float64, dataset.Dataset, dataset.Dataset) {
	var best_name string
	var best_value float64
	var best_left dataset.Dataset
	var best_right dataset.Dataset
	var best_gini float64

	for i, col := range ds.Columns {
		switch col.Type {
		case "numeric", "catagorical":
			for _, value := range ds.Gaps(i) {
				lhs, rhs := ds.Split(i, value)

				if len(lhs.Targets()) > 0 && len(rhs.Targets()) > 0 {
					g := 1.0 - gini_index(lhs, rhs, ds.Targets())

					if best_name == "" || g > best_gini {
						best_name = ds.Columns[i].Name
						best_value = value
						best_left = lhs
						best_right = rhs
						best_gini = g
					}
				}
			}
		}
	}

	return best_name, best_value, best_left, best_right
}

func build_tree(ds dataset.Dataset, depth int) tree.Tree {
	best_name, best_value, best_left, best_right := best_split(ds)

	if best_name == "" || depth > max_depth {
		return tree.NewResult(strings.Join(ds.ActiveTargets(), "/"))
	}

	col_idx := ds.ColumnIndex(best_name)
	var root tree.Tree

	if ds.Columns[col_idx].Type == "catagorical" {
		root = tree.NewTree(best_name, "==", ds.Columns[col_idx].Symbols[int(best_value)])
	} else {
		root = tree.NewTree(best_name, "<", fmt.Sprintf("%f", best_value))
	}

	if len(best_left.ActiveTargets()) == 1 {
		root.SetIfTrue(tree.NewResult(best_left.ActiveTargets()[0]))
	} else {
		root.SetIfTrue(build_tree(best_left, depth+1))
	}

	if len(best_right.ActiveTargets()) == 1 {
		root.SetIfFalse(tree.NewResult(best_right.ActiveTargets()[0]))
	} else {
		root.SetIfFalse(build_tree(best_right, depth+1))
	}

	return root
}

func Gini(ds dataset.Dataset, output string) {
	solution := build_tree(ds, 0)
	solution.Dump(output)
}
