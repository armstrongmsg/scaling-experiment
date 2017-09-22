# include <stdio.h>
# include <stdlib.h>
# include <time.h>

int _debug;

void debug(char *str)
{
	if (_debug)
	{
		puts(str);
	}
}

int main(int c, char **args)
{
	int iterations = atoi(args[1]);
	char *filename = args[2];
	unsigned long int start_time, write_time, end_time = 0;
	char buffer[10];
	_debug = atoi(args[3]);
	int executions = atoi(args[4]);

	printf("iterations:%d\n", iterations);
	printf("output file name:%s\n", filename);
	printf("debug:%d\n", _debug);
	printf("executions:%d\n", executions);

	int e;
	for (e = 0; e < executions; e++)
	{
		start_time = time(NULL);

		debug("Opening file");
		FILE *output_file = fopen(filename, "w");
		int i = 0;

		debug("Writing to file");
		for (i = 0; i < iterations; i++)
		{
			fputs("aaaaaaaaaa", output_file);
		}

		debug("Flushing");
		fflush(output_file);
		fsync(fileno(output_file));

		debug("Closing file");
		fclose(output_file);

		write_time = time(NULL);

		debug("Opening file");
		output_file = fopen(filename, "r");

		debug("Reading from file");
		for (i = 0; i < iterations; i++)
		{
			fgets(buffer, 10, output_file);
		}

		remove(filename);
		end_time = time(NULL);

		unsigned long int total_time = end_time - start_time;
		unsigned long int write_total_time = write_time - start_time;
		unsigned long int read_total_time = end_time - write_time;

		printf("%lu,%lu,%lu\n", total_time, write_total_time, read_total_time);
	}

	return 0;
}
