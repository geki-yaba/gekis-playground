## LibreOffice ##

### My most painful OpenOffice.org features ###

  * Calc/Chart (science) super-/subscript formatting<br>
<a href='http://qa.openoffice.org/issues/show_bug.cgi?id=11890'>i11890 - Ability to edit legend text / modify series names</a></li></ul>


<h3>Why system version over internal one? ###

  * (security) patches are included faster
  * update the library or openoffice? ...
  * able to use the same library for other applications (load only once → use less memory)
  * reduce the f..king build time!


### System variable ###

<u>set style of widgets</u>

SAL\_USE\_VCLPLUGIN - 'gen', 'gtk' or 'kde4'

```
 # example
 export SAL_USE_VCLPLUGIN=gtk
```

### Why do you want it over portage version? ###
  * no gtk dep for kde-only
  * jemalloc allocator
  * more useflags
  * **epatch\_user** - add your patches like postgresql, ...
  * ... whatever I forgot to mention

_there are various extensions to libreoffice._<br>
you may check './configure --help' for '--enable-ext-...'<br>
and request them here<br>
<br>
<h3>Known issues</h3>

<ul><li>libreoffice-3.4.0: calc crashes on dnd here and there?! take care ...</li></ul>


<h3>Good to know about ...</h3>

<u>hack source</u>

<ul><li>enter openoffice environment</li></ul>

<pre><code> export ARCH_FLAGS="&lt;CXXFLAGS&gt;"<br>
 export LINKFLAGSOPTIMIZE="&lt;LDFLAGS&gt;"<br>
 export S=/var/tmp/portage/app-office/libreoffice*/work/libreoffice*/build/libreoffice*<br>
 cd $S<br>
 export LinuxEnvSet="Linux&lt;ARCH&gt;Env.Set.sh"<br>
 source $S/$LinuxEnvSet<br>
<br>
 # optional: build with debugging symbols<br>
 # '-s' will strip the code anyway!<br>
 export ENABLE_SYMBOLS=TRUE<br>
 export DISABLE_STRIP=TRUE<br>
<br>
 ... hack the source ...<br>
</code></pre>

<u>generating a system-locale-encoded <i>const char pointer</i> (from rtl_uString)</u>

<ul><li><a href='http://api.openoffice.org/docs/cpp/ref/names/rtl/c-OUString.html'>http://api.openoffice.org/docs/cpp/ref/names/rtl/c-OUString.html</a>
</li><li><a href='http://api.openoffice.org/docs/cpp/ref/names/rtl/c-OString.html'>http://api.openoffice.org/docs/cpp/ref/names/rtl/c-OString.html</a></li></ul>

<pre><code> #include &lt;iostream&gt;<br>
 #include &lt;rtl/ustring.hxx&gt;<br>
 <br>
 ...<br>
 <br>
 rtl_uString* ustr = ...;<br>
 <br>
 ...<br>
 <br>
 OString ostr;<br>
 OUString oustr( ustr );<br>
 oustr.convertToString( &amp;ostr,<br>
   osl_getTextEncodingFromLocale( NULL ),<br>
   RTL_UNICODETOTEXT_FLAGS_INVALID_UNDERLINE );<br>
 <br>
 /* alternative flags are:<br>
  * RTL_UNICODETOTEXT_FLAGS_INVALID_QUESTIONMARK<br>
  * RTL_UNICODETOTEXT_FLAGS_INVALID_0<br>
  */<br>
 <br>
 /* print system-locale-encoded 'const char *' */<br>
 std::cout &lt;&lt; ostr.getStr() &lt;&lt; std::endl;<br>
</code></pre>