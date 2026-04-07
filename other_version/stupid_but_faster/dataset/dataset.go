package dataset

import (
	"bufio"
	"fmt"
	"log"
	"math/rand"
	"os"
	"slices"
	"strconv"
	"strings"
)

type DatasetColumn struct {
	Name    string
	Type    string
	Symbols []string
}

type Dataset struct {
	Columns      []DatasetColumn
	Rows         [][]float64
	TargetColumn int
	NameIndex    map[string]int
}

func (ds *Dataset) AddColumn(text string, line_number int) {
	parts := strings.Fields(text)

	if len(parts) != 2 {
		log.Fatalf("Invalid column definition at line %d\n", line_number)
	}

	name := parts[0][1:len(parts[0])]
	ctype := parts[1]
	validColumnType(ctype)

	if ctype == "target" {
		ds.TargetColumn = len(ds.Columns)
	}

	ds.NameIndex[name] = len(ds.Columns)
	ds.Columns = append(ds.Columns, DatasetColumn{name, ctype, []string{}})
}

func (ds *Dataset) AddRow(text string, line_number int) {
	parts := strings.Split(text, ",")

	if len(parts) != len(ds.Columns) {
		if len(ds.Columns) == 0 {
			log.Fatalf("Loading data but the columns have not been defined at line %d\n", line_number)
		} else {
			log.Fatalf("%d columns have been defined but row has %d columns at line %d\n", len(ds.Columns), len(parts), line_number)
		}
	}

	r := make([]float64, len(parts))

	for i, v := range parts {
		s := strings.TrimSpace(v)

		if ds.Columns[i].Type == "numeric" {
			f, _ := strconv.ParseFloat(s, 64)
			r[i] = f
		} else {
			at := slices.Index(ds.Columns[i].Symbols, s)
			if at == -1 {
				ds.Columns[i].Symbols = append(ds.Columns[i].Symbols, s)
				at = len(ds.Columns[i].Symbols) - 1
			}
			r[i] = float64(at)
		}
	}

	ds.Rows = append(ds.Rows, r)
}

func (ds *Dataset) CopyStructure() Dataset {
	// Making sure it is a deep copy
	nds := Dataset{TargetColumn: ds.TargetColumn}

	for _, col := range ds.Columns {
		s := make([]string, len(col.Symbols))
		copy(s, col.Symbols)

		nds.Columns = append(nds.Columns, DatasetColumn{Name: col.Name, Type: col.Type, Symbols: s})
	}

	return nds
}

func (ds *Dataset) Save(filename string, header string) {
	fo, err := os.Create(filename)
	if err != nil {
		log.Fatal(err)
	}
	defer fo.Close()

	fo.WriteString(fmt.Sprintf("# %s\n\n", header))
	for _, v := range ds.Columns {
		fo.WriteString(fmt.Sprintf("@%s %s\n", v.Name, v.Type))
	}
	fo.WriteString("\n")

	for _, row := range ds.Rows {
		s := make([]string, len(ds.Columns))

		for i, col := range ds.Columns {
			if col.Type == "numeric" {
				s[i] = fmt.Sprintf("%f", row[i])
			} else {
				s[i] = col.Symbols[int(row[i])]
			}
		}

		fo.WriteString(fmt.Sprintf("%s\n", strings.Join(s, ",")))
	}
}

func (ds *Dataset) Targets() []float64 {
	l := make([]float64, len(ds.Columns[ds.TargetColumn].Symbols))

	for i := range l {
		l[i] = float64(i)
	}

	return l
}

func (ds *Dataset) ActiveTargets() []string {
	var x []string

	for _, row := range ds.Rows {
		v := int(row[ds.TargetColumn])
		s := ds.Columns[ds.TargetColumn].Symbols[v]

		if !slices.Contains(x, s) {
			x = append(x, s)
		}
	}

	return x
}

func (ds *Dataset) Size() int {
	return len(ds.Rows)
}

func (ds *Dataset) Gaps(index int) []float64 {
	// Remember there might be no gap!

	sorted_values := []float64{}

	for _, row := range ds.Rows {
		v2 := row[index]

		if !slices.Contains(sorted_values, v2) {
			sorted_values = append(sorted_values, v2)
		}
	}

	slices.Sort(sorted_values)

	var gaps []float64
	var prev_value float64
	prev := false

	for _, value := range sorted_values {
		if prev {
			gap := prev_value + ((value - prev_value) / 2.0)
			gaps = append(gaps, gap)
		} else {
			prev = true
		}

		prev_value = value
	}

	return gaps
}

func (ds *Dataset) Split(index int, value float64) (Dataset, Dataset) {
	lhs := ds.CopyStructure()
	rhs := ds.CopyStructure()

	for _, row := range ds.Rows {
		v2 := row[index]

		if v2 < value {
			lhs.Rows = append(lhs.Rows, row)
		} else {
			rhs.Rows = append(rhs.Rows, row)
		}
	}

	return lhs, rhs
}

func (ds *Dataset) ColumnIndex(name string) int {
	for i, col := range ds.Columns {
		if col.Name == name {
			return i
		}
	}

	// TODO: Maybe this should be an error
	return -1
}

func (ds *Dataset) RowTarget(i int) string {
	tc := ds.TargetColumn
	ti := int(ds.Rows[i][tc])
	return ds.Columns[tc].Symbols[ti]
}

func RandomSplitList(list []float64, size int) ([]float64, []float64) {
	var sub_list []float64

	for i := 0; i < size; i++ {
		i := rand.Intn(len(list))
		sub_list = append(sub_list, list[i])
		list = append(list[:i], list[i+1:]...)
	}

	return sub_list, list
}

func LoadFromFile(filename string) Dataset {
	file, err := os.Open(filename)
	if err != nil {
		log.Fatal(err)
	}
	defer file.Close()

	scanner := bufio.NewScanner(file)

	ds := Dataset{NameIndex: make(map[string]int)}
	line_number := 0

	for scanner.Scan() {
		s := scanner.Text()
		text := strings.ToLower(s)

		line_number++

		if strings.HasPrefix(text, "#") {
			// println("A comment")
		} else if strings.HasPrefix(text, "@") {
			ds.AddColumn(text, line_number)
		} else if strings.Contains(text, ",") {
			ds.AddRow(text, line_number)
		}
	}

	if err := scanner.Err(); err != nil {
		log.Fatal(err)
	}

	return ds
}

func validColumnType(ctype string) bool {
	switch ctype {
	case "numeric":
		return true
	case "catagorical":
		return true
	case "target":
		return true
	default:
		log.Fatalf("A column is either numeric, catagorical or target. Not [%s]\n", ctype)

		return false
	}
}
