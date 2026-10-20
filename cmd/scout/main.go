package main

import (
	"fmt"
	"os"
)

func main() {
	if len(os.Args) < 2 {
		fmt.Println("usage: scout <index|query|stats|bench>")
		os.Exit(1)
	}

	switch os.Args[1] {
	case "index", "query", "stats", "bench":
		fmt.Printf("%s: not implemented yet\n", os.Args[1])
	default:
		fmt.Printf("unknown command: %s\n", os.Args[1])
		os.Exit(1)
	}
}
