diff:
	gcc diff.s -no-pie -g -o diff.out
	./diff.out text1 text2

args:
	gcc args.s -no-pie -g -o args.out 
	./args.out xde x23

compare:
	gcc compare_args.s -no-pie -g -o compare_args.out 
	./compare_args.out xde x23
