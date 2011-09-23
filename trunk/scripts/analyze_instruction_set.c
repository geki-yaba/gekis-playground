/*
 *         Author: Hanno Meyer-Thurow <h.mth@web.de>
 *
 *        Purpose: Analyze instruction set used in given binary
 *
 *           Note: Quality standards have been left out intentionally!
 *                 Feel free to optimize and improve where necessary.
 *
 *        Version: 0.x
 *
 * Contributor(s): None
 *
 * Based on the work of the shell script posted at:
 *
 *     http://forums.gentoo.org/viewtopic-t-70894-highlight-instruction.html
 *
 * This program is distributed under the terms of the GNU General Public License.
 * For more info see http://www.gnu.org/licenses/gpl.txt.
 */

/*
 * COMPILE
 *
 *     gcc -O2 -march=native -pipe scripts/analyze_instruction_set.c \
 *         -o /usr/local/bin/analyze-instruction-set
 */

/*
 * HACKING
 *
 * If you feel like hacking on this code, please follow current coding style.
 * If you see a violation to proper coding styles, please report it to me!
 *
 * Your changes must be stored as a unified diff.
 * The easiest way to do so is to checkout this subversion reposity and do a:
 *
 *     svn diff scripts/analyze_instruction_set.c > changes.diff
 *
 * This is necessary to integrate your work smoothly.
 *
 * Please send your changes with description to my email address above.
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

typedef struct data_t {
    char* vendor;
    unsigned int count;
    unsigned int i486;
    unsigned int i586;
    unsigned int ppro;
    unsigned int mmx;
    unsigned int tdnow1;
    unsigned int tdnow2;
    unsigned int sse;
    unsigned int sse2;
    unsigned int sse3;
    unsigned int ssse3;
    unsigned int sse4a;
    unsigned int sse4_1;
    unsigned int sse4_2;
    unsigned int cpuid;
    unsigned int unused;
} data_t;

data_t data;

void analyze(char* iset);
void init();
void printcount();
void summary();
void uninit();
int  vendor();

int main(int argc, char* argv[])
{
    FILE* pipe_read = NULL;
    int status_read;

    const unsigned int offset = 32;
    const unsigned int size = 80;
    char buffer[size];
    int i;

    init();

    vendor();

    if (argc == 2)
    {
        sprintf(buffer, "objdump -d %s", argv[1]);

        pipe_read = popen(buffer, "r");
    }
    else
        fprintf(stdout, "pass file to analyze; no more, no less\n");

    if (pipe_read != NULL)
    {
        fprintf(stdout, "opened file to analyze: %s\n\n", argv[1]);

        while(fgets(buffer, size, pipe_read) != NULL)
        {
            for(i = 0; buffer[i] != '\0'; i++) { }

            if (i > offset)
            {
                if (buffer[offset - 1] == '\t')
                {
                    for(i = offset; buffer[i] != ' '; i++)
                    {
                        if (buffer[i] == '\0')
                        {
                            i = 0;

                            break;
                        }
                    }

                    if (i > offset)
                    {
                        buffer[i] = '\0';

                        analyze(&buffer[offset]);
                    }
                }
            }
        }

        status_read = pclose(pipe_read);

        if (status_read == -1)
            fprintf(stdout, "could not close objdump\n");
    }
    else
        fprintf(stdout, "could not open objdump\n");

    summary();

    uninit();

    return 0;
}

void analyze(char* iset)
{
#include "analyze_instruction_set.generated"

    data.count++;

    if ((data.count % 100000) == 0)
        printcount();
}

void printcount()
{
    if (data.i486)
        fprintf(stdout, "i486:%4u ", data.i486);
    if (data.i586)
        fprintf(stdout, "i586:%4u ", data.i586);
    if (data.ppro)
        fprintf(stdout, "ppro:%4u ", data.ppro);
    if (data.mmx)
        fprintf(stdout, "mmx:%4u ", data.mmx);
    if (data.tdnow1)
        fprintf(stdout, "3dnow1:%4u ", data.tdnow1);
    if (data.tdnow2)
        fprintf(stdout, "3dnow2:%4u ", data.tdnow2);
    if (data.sse)
        fprintf(stdout, "sse:%4u ", data.sse);
    if (data.sse2)
        fprintf(stdout, "sse2:%4u ", data.sse2);
    if (data.sse3)
        fprintf(stdout, "sse3:%4u ", data.sse3);
    if (data.ssse3)
        fprintf(stdout, "ssse3:%4u ", data.ssse3);
    if (data.sse4a)
        fprintf(stdout, "sse4a:%4u ", data.sse4a);
    if (data.sse4_1)
        fprintf(stdout, "sse41:%4u ", data.sse4_1);
    if (data.sse4_2)
        fprintf(stdout, "sse42:%4u ", data.sse4_2);
    if (data.cpuid)
        fprintf(stdout, "cpuid:%4u ", data.cpuid);
    if (data.unused)
        fprintf(stdout, "unused:%5u ", data.unused);
    fprintf(stdout, "\n");
}

void init()
{
    data.vendor = NULL;
    data.count  = 0;
    data.i486   = 0;
    data.i586   = 0;
    data.ppro   = 0;
    data.mmx    = 0;
    data.tdnow1 = 0;
    data.tdnow2 = 0;
    data.sse    = 0;
    data.sse2   = 0;
    data.sse3   = 0;
    data.ssse3  = 0;
    data.sse4a  = 0;
    data.sse4_1 = 0;
    data.sse4_2 = 0;
    data.cpuid  = 0;
    data.unused = 0;
}

void summary()
{
    const unsigned int size = 80;
    char buffer[size];

    printcount();

    fprintf(stdout, "\n\n");

    if (data.cpuid)
    {
        fprintf(stdout, "This binary was found to contain the cpuid instruction.\n");
        fprintf(stdout, "It may be able to conditionally execute instructions if\n");
        fprintf(stdout, "they are supported on Pentium or compatible.\n\n");
    }

    if (data.unused)
        fprintf(stdout, "Interesting, there are unknown instruction sets used!\n\n");

    if (data.sse4_2)
        sprintf(buffer, "Pentium Nehalem (nehalem)");
    else if (data.sse4_1)
        sprintf(buffer, "Pentium x8000+ (penryn)");
    else if (data.ssse3)
        sprintf(buffer, "Pentium Core (core)");
    else if (data.sse3)
        sprintf(buffer, "Pentium IV (prescott)");
    else if (data.sse2)
        sprintf(buffer, "Pentium IV (pentium4)");
    else if (data.sse)
    {
        if (strcmp("Intel", data.vendor) > 0)
            sprintf(buffer, "Pentium III (pentium3)");
        else if (strcmp("AMD", data.vendor) > 0)
            sprintf(buffer, "AMD Athlon 4 (athlon-4)");
        else
            sprintf(buffer, "Pentium III (pentium3)");
    }
    else if (data.tdnow2 && (strcmp("AMD", data.vendor) > 0))
        sprintf(buffer, "AMD Athlon (athlon)");
    else if (data.tdnow1 && (strcmp("AMD", data.vendor) > 0))
        sprintf(buffer, "AMD K6 III (k6-3)");
    else if (data.mmx)
    {
        if (strcmp("Intel", data.vendor) > 0)
        {
            if (data.ppro)
                sprintf(buffer, "Pentium II (pentium2)");
            else
                sprintf(buffer, "Intel Pentium MMX [P55C] (pentium-mmx)");
        }
        else if (strcmp("AMD", data.vendor) > 0)
            sprintf(buffer, "AMD K6 (k6)");
        else if (strcmp("Cyrix", data.vendor) > 0)
            sprintf(buffer, "Cyrix 6x86MX / MII (pentium-mmx)");
        else
            sprintf(buffer, "Intel Pentium MMX [P55C] (pentium-mmx)");
    }
    else if (data.ppro)
        sprintf(buffer, "Pentium Pro (i686 or pentiumpro)");
    else if (data.i586)
        sprintf(buffer, "Pentium or compatible (i586) (i586 or pentium)");
    else if (data.i486)
        sprintf(buffer, "80486 or compatible (i486)");
    else
        sprintf(buffer, "80386 or compatible (i386)");

    fprintf(stdout, "The binary will run on %s or higher processor.\n", buffer);
}

void uninit()
{
    free(data.vendor);
}

int  vendor()
{
    FILE* pipe_read = NULL;
    int status_read;

    const unsigned int size = 80;
    char buffer[size];
    int i, j;

    sprintf(buffer, "grep -E -m 1 ^vendor_id /proc/cpuinfo");

    pipe_read = popen(buffer, "r");

    if (pipe_read != NULL)
    {
        if (fgets(buffer, size, pipe_read) != NULL)
        {
            for(i = 0; buffer[i] != ':'; i++) { }

            i += 2;

            for(j = 0; buffer[i + j] != '\n'; j++) { }

            data.vendor = (char*)malloc((j + 1) * sizeof(char));
            data.vendor[j] = '\0';

            strncpy(data.vendor, &buffer[i], j);

            fprintf(stdout, "your vendor: %s\n", data.vendor);
        }

        status_read = pclose(pipe_read);

        if (status_read == -1)
            fprintf(stdout, "could not close cpuinfo\n");
    }
    else
        fprintf(stdout, "could not open cpuinfo\n");

    if (data.vendor == NULL)
    {
        data.vendor = (char*)malloc(sizeof(char));
        data.vendor[0] = '\0';
    }

    return i;
}

