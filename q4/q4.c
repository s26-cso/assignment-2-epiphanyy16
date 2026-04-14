#include <stdio.h>
#include <stdlib.h>
#include <dlfcn.h>

int main() {
    char op[6];
    int num1, num2;

    while (scanf("%5s %d %d", op, &num1, &num2) == 3) {
        char libname[20];
        snprintf(libname, sizeof(libname), "./lib%s.so", op);
        dlerror(); // clearing any existing error
        // opening library and finding function
        void *libptr = dlopen(libname, RTLD_LAZY);
        if (!libptr) {
            fprintf(stderr, "Error loading library: %s\n", dlerror());
            continue;
        }
        typedef int (*op_func)(int, int);
        op_func func = (op_func)dlsym(libptr, op);
        
        char *error = dlerror();
        if (error != NULL) {
            fprintf(stderr, "Error finding function: %s\n", error);
            dlclose(libptr);
            continue;
        }
        printf("%d\n", func(num1, num2));
        dlclose(libptr);
    }
    
    return 0;
}
