# include <stdio.h>
# include <stdlib.h>

int main(int c, char **args)
{
	int iterations = atoi(args[1]);
	char *filename = args[2];

	printf("iterations:%d\n", iterations);
	printf("output file name:%s\n", filename);

	puts("Opening file");
	FILE *output_file = fopen(filename, "r+");	
	int i = 0;

	for (; i < iterations; i++)
	{
		fputs("aaaaaaaaaa", output_file);
	}

	puts("Flushing");
	fflush(output_file);
	fsync(fileno(output_file));

	puts("Closing file");
	fclose(output_file);

	return 0;
}
