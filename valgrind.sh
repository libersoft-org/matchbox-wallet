valgrind --tool=memcheck --leak-check=no --track-origins=no --show-reachable=no --undef-value-errors=no --suppressions=valgrind.supp --gen-suppressions=yes   --num-callers=200  ./build/linux/wallet
