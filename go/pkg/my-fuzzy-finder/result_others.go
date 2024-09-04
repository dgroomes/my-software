// THIS IS A COPY from https://github.com/junegunn/fzf/tree/8af0af3400fc36651b59a7e3f9a2bedd4a51daed
// MIT LICENSE

//go:build !386 && !amd64

package main

func compareRanks(irank Result, jrank Result, tac bool) bool {
	for idx := 3; idx >= 0; idx-- {
		left := irank.points[idx]
		right := jrank.points[idx]
		if left < right {
			return true
		} else if left > right {
			return false
		}
	}
	return (irank.item.Index() <= jrank.item.Index()) != tac
}
