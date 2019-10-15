diff:
	gcc diff.s -no-pie -ggdb3 -o diff.out
	./diff.out -i -B tests/test2a tests/test2b
diffd:
	gcc diff.s -no-pie -ggdb3 -o diff.out
	gdb --args ./diff.out -i -B tests/test2a tests/test2b
