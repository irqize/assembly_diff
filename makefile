diff: diff.out
	gcc diff.s -no-pie -g -o diff.out
	./diff.out

args: args.out
	gcc args.s -no-pie -g -o args.out 
	./args.out xde 123
