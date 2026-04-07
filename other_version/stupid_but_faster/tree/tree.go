package tree

import (
	"encoding/json"
	"log"
	"os"
	"strconv"

	"classify/dataset"
)

type Tree struct {
	Feature  string `json:"Feature"`
	Relation string `json:"Relation"`
	Value    string `json:"Value"`
	IfTrue   *Tree  `json:"IfTrue"`
	IfFalse  *Tree  `json:"IfFalse"`
}

func NewTree(feature string, relation string, value string) Tree {
	return Tree{Feature: feature, Relation: relation, Value: value}
}

func NewResult(value string) Tree {
	return Tree{Value: value}
}

func (t *Tree) IsResult() bool {
	return t.Feature == ""
}

func (t *Tree) SetIfTrue(other Tree) {
	t.IfTrue = &other
}

func (t *Tree) SetIfFalse(other Tree) {
	t.IfFalse = &other
}

func (t *Tree) Dump(filename string) {
	s, _ := json.Marshal(t)

	fo, err := os.Create(filename)
	if err != nil {
		panic(err)
	}

	defer fo.Close()

	fo.Write(s)
}

func (t *Tree) Walk(ds dataset.Dataset, row int) bool {
	if t.IsResult() {
		actual := t.Value
		expected := ds.RowTarget(row)

		return actual == expected
	}

	a_val, _ := strconv.ParseFloat(t.Value, 64)

	fi := ds.NameIndex[t.Feature]
	val := ds.Rows[row][fi]

	var res bool
	switch t.Relation {
	case "<":
		res = val < a_val
	case "==":
		res = val == a_val
	default:
		log.Fatalf("Unknown relation [%s]\n", t.Relation)
	}

	if res {
		return t.IfTrue.Walk(ds, row)
	} else {
		return t.IfFalse.Walk(ds, row)
	}

	return false
}

func Load(filename string) Tree {
	var t Tree

	data, err := os.ReadFile(filename)
	if err != nil {
		panic(err)
	}

	err = json.Unmarshal(data, &t)

	if err != nil {
		panic(err)
	}

	return t
}
