diff:
	gcc diff.s -no-pie -ggdb3 -o diff.out
	./diff.out tests/test2a tests/test2b

