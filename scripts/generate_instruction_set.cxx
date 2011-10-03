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
 * The easiest way to do so is to checkout this subversion repository and do a:
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

private:
    void loop(std::string& str)
    {
        for(blobmap::iterator
            i = blobs.begin(),
            e = blobs.end();
            i != e;
            i++)
            i->second << str;
    }

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

    void operator<<(std::string& str)
    {
        if (rewind())
            data += str;

        loop(str);

        back = false;
        fix  = false;
    }

    blobmap& children() { return blobs; }

    std::string& code() { return data; }
    std::string& name() { return parse; }

    unsigned int whitespace() { return indent; }

    void decrement() { indent--; }
    void increment() { indent++; }

    char type() { return c; }

    bool rewind() { return back; }
    void rewind(bool r) { back = r; }

    bool fill() { return fix; }
    void fill(bool f) { fix = f; }
};

template <class charT, class traits>
std::basic_istream<charT,traits>& operator>>(std::basic_istream<charT,traits>& is, blob& b)
{
    char c;
    is >> c;

    if (is.good())
    {
        // end of instructions
        if (c == ')')
        {
            // fill this blob with itype
            b.rewind(true);

            // roll "rewind" blobs with itype
            b.fill(true);
        }
        // end of instruction
        else if (c == '|')
        {
            // fill this blob with itype
            b.rewind(true);
        }
        else
        {
            blob::blobmap::iterator i = b.children().find(c);

            if (i == b.children().end())
                i = b.children().insert(std::make_pair(c,
                    blob(b.whitespace() + 1, c, b.name())));

            blob& n = i->second;

            // recursion
            is >> n;

            if (n.fill())
                b.fill(true);
        }
    }

    return is;
}

template<class charT, class traits>
std::basic_ostream<charT,traits>& operator<<(std::basic_ostream<charT,traits>& os, blob& b)
{
    os << std::string(b.whitespace() * 4, ' ');

    if (b.type() == ':')
        os << "unsigned int i = 0;" << std::endl;
    else
    {
        os << "case '" << b.type() << "':";

        if (! b.code().empty())
            os << " /* " << b.name() << " */";

        os << std::endl;

        b.increment();
    }

    if (! b.code().empty())
    {
        os << std::string(b.whitespace() * 4, ' ');
        os << "if (iset[i] == '\\0') { " << b.code() << " }" << std::endl;

        if (b.children().size())
        {
            os << std::string(b.whitespace() * 4, ' ');
            os << "else" << std::endl;
        }
    }

    if (b.children().size())
    {
        os << std::string(b.whitespace() * 4, ' ');
        os << "switch(iset[i++])" << std::endl;

        os << std::string(b.whitespace() * 4, ' ');
        os << "{" << std::endl;

        for(blob::blobmap::iterator
            i = b.children().begin(),
            e = b.children().end();
            i != e;
            i++)
            os << i->second;

        os << std::string(b.whitespace() * 4, ' ');
        os << "default:" << std::endl;

        os << std::string((b.whitespace() + 1) * 4, ' ');
        os << "++data.unused;" << std::endl;

        os << std::string((b.whitespace() + 1) * 4, ' ');
        os << "break;" << std::endl;

        os << std::string(b.whitespace() * 4, ' ');
        os << "}" << std::endl;
    }

    if (b.type() != ':')
    {
        os << std::string(b.whitespace() * 4, ' ');
        os << "break;" << std::endl;

        b.decrement();
    }

    return os;
}

int main()
{
    std::ifstream is("analyze_instruction_set.data");

    blob b(1, ':');

    while(! is.eof())
    {
        is >> b;

        if (b.fill())
        {
            const unsigned int size = 1024;
            char buffer[size];

            is.getline(buffer, size);

            std::string data(buffer);

            b << data;
        }
    }

    std::ofstream os("analyze_instruction_set.generated");

    if (os.good())
        os << b;

    return 0;
}

