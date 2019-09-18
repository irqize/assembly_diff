diff: diff.o
	gcc diff.s -no-pie -g -o diff.out
	./diff.out
