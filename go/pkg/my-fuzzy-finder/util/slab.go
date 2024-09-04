// THIS IS A COPY from https://github.com/junegunn/fzf/tree/8af0af3400fc36651b59a7e3f9a2bedd4a51daed
// MIT LICENSE

package util

type Slab struct {
	I16 []int16
	I32 []int32
}

func MakeSlab(size16 int, size32 int) *Slab {
	return &Slab{
		I16: make([]int16, size16),
		I32: make([]int32, size32)}
}
