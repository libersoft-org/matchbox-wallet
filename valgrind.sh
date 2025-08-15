valgrind --tool=memcheck --leak-check=no --track-origins=no --show-reachable=no --undef-value-errors=no --suppressions=valgrind.supp --gen-suppressions=yes  ./build/linux/wallet
