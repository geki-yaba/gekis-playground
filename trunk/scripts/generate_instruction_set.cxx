/*
 *         Author: Hanno Meyer-Thurow <h.mth@web.de>
 *
 *        Purpose: Generate C style switch block to analyze 'char*'
 *
 *           Note: Quality standards have been left out intentionally!
 *                 Feel free to optimize and improve where necessary.
 *
 *        Version: 0.x
 *
 * Contributor(s): None
 *
 * This program is distributed under the terms of the GNU General Public License.
 * For more info see http://www.gnu.org/licenses/gpl.txt.
 */

/*
 * COMPILE
 *
 *     cd scripts/
 *     g++ -O2 -march=native -pipe generate_instruction_set.cxx \
 *         -o generate-instruction-set
 */

/*
 * EXECUTE
 *
 *     cd scripts/
 *     ./generate-instruction-set
 */

/*
 * NOTE
 *
 *     Since this is just a helper tool you may compile and execute this script
 *     in the scripts/ directory. Just be lazy and do change into the directory.
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
 *     svn diff scripts/generate_instruction_set.cxx > changes.diff
 *
 * This is necessary to integrate your work smoothly.
 *
 * Please send your changes with description to my email address above.
 */

#include <iostream>
#include <fstream>

#include <map>
#include <string>
#include <utility>

class blob
{
public:
    typedef std::multimap<char, blob> blobmap;

private:
    blobmap blobs;

    std::string parse;
    std::string data;

    unsigned int indent;

    char c;

    bool back;
    bool fix;

public:
    // root
    blob(unsigned int i, char k)
     : blobs(),
       parse(),
       data(),
       indent(i),
       c(k),
       back(false),
       fix(false)
    {
    }

    // children
    blob(unsigned int i, char k, std::string& p)
     : blobs(),
       parse(p + k),
       data(),
       indent(i),
       c(k),
       back(false),
       fix(false)
    {
    }

    ~blob()
    {
    }

    void next(std::ifstream& is)
    {
        if (is.good())
        {
            char i;
            is >> i;

            // end of instructions
            if (i == ')')
            {
                // fill this blob with itype
                back = true;
    
                // roll "rewind" blobs with itype
                fix = true;
            }
            // end of instruction
            else if (i == '|')
            {
                // fill this blob with itype
                back = true;
            }
            else
            {
                blobmap::iterator m = blobs.find(i);
    
                if (m == blobs.end())
                    m = blobs.insert(std::make_pair(i, blob(indent + 1, i, name())));

                blob& b = m->second;

                b.next(is);

                if (b.fill())
                    fix = true;
            }
        }
    }

    void fill(std::string& str)
    {
        if (rewind())
            data += str;

        loop(str);

        back = false;
        fix  = false;
    }

    void loop(std::string& str)
    {
        for(blobmap::iterator
            i = blobs.begin(),
            e = blobs.end();
            i != e;
            i++)
        {
            blob& b = i->second;

            b.fill(str);
        }
    }

    void print(std::ostream& os)
    {
        os << std::string(indent * 4, ' ');

        if (c == ':')
            os << "unsigned int i = 0;" << std::endl;
        else
        {
            os << "case '" << c << "':";

            if (! data.empty())
                os << " /* " << name() << " */";

            os << std::endl;

            indent++;
        }

        if (! data.empty())
        {
            os << std::string(indent * 4, ' ');
            os << "if (iset[i] == '\\0') { " << data << " }" << std::endl;

            if (blobs.size())
            {
                os << std::string(indent * 4, ' ');
                os << "else" << std::endl;
            }
        }

        if (blobs.size())
        {
            os << std::string(indent * 4, ' ');
            os << "switch(iset[i++])" << std::endl;

            os << std::string(indent * 4, ' ');
            os << "{" << std::endl;
        }

        for(blobmap::iterator
            i = blobs.begin(),
            e = blobs.end();
            i != e;
            i++)
        {
            blob& b = i->second;

            b.print(os);
        }

        if (blobs.size())
        {
            os << std::string(indent * 4, ' ');
            os << "default:" << std::endl;

            os << std::string((indent + 1) * 4, ' ');
            os << "++data.unused;" << std::endl;

            os << std::string((indent + 1) * 4, ' ');
            os << "break;" << std::endl;

            os << std::string(indent * 4, ' ');
            os << "}" << std::endl;
        }

        if (c != ':')
        {
            os << std::string(indent * 4, ' ');
            os << "break;" << std::endl;

            indent--;
        }
    }

    std::string& name() { return parse; }

    bool rewind() { return back; }
    bool fill() { return fix; }
};

int main()
{
    std::ifstream is("analyze_instruction_set.data");

    blob b(1, ':');

    while(! is.eof())
    {
        b.next(is);

        if (b.fill())
        {
            const unsigned int size = 1024;
            char buffer[size];

            is.getline(buffer, size);

            std::string data(buffer);

            b.fill(data);
        }
    }

    std::ofstream os("analyze_instruction_set.generated");

    os.flags(std::ios::right);

    if (os.good())
        b.print(os);

    return 0;
}

