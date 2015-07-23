# See bottom of file for license and copyright information

# Tests for extensions to the two translators, TML to HTML and HTML to TML,
# that support editing using WYSIWYG HTML editors. The tests are designed
# so that the round trip can be verified in as many cases as possible.
# Readers are invited to add more testcases.
#
# The tests require FOSWIKI_LIBS to include a pointer to the lib
# directory of a Foswiki installation, so it can pick up the bits
# of Foswiki it needs to include.
#
package ExtendedTranslatorTests;
use TranslatorBase;
use TranslatorTests;
our @ISA = qw( TranslatorTests );

use strict;
use warnings;

require Foswiki::Plugins::WysiwygPlugin;
require Foswiki::Plugins::WysiwygPlugin::Handlers;
require Foswiki::Plugins::WysiwygPlugin::TML2HTML;
require Foswiki::Plugins::WysiwygPlugin::HTML2TML;

my $deleteme = '<p class="foswikiDeleteMe">&nbsp;</p>';

# Holds extra options to be passed to the TML2HTML convertor
my %extraTML2HTMLOptions;

# See TranslatorTests for details of how these tests work
my $data = [
    {
        exec  => TML2HTML | ROUNDTRIP,
        name  => 'UnspecifiedCustomXmlTag',
        setup => sub {
            $extraTML2HTMLOptions{xmltag} =
              \%Foswiki::Plugins::WysiwygPlugin::xmltag;
        },
        html => '<p>'
          . $PROTECTON
          . '&lt;customtag&gt;'
          . $PROTECTOFF
          . 'some &gt;'
          . TranslatorTests::encodedWhitespace('s2') . 'text'
          . $PROTECTON
          . '&lt;/customtag&gt;'
          . $PROTECTOFF . '</p>',
        tml      => '<customtag>some >  text</customtag>',
        finaltml => '<customtag>some &gt;  text</customtag>',
    },
    {
        exec  => TML2HTML | ROUNDTRIP,
        name  => 'DisabledCustomXmlTag',
        setup => sub {
            $extraTML2HTMLOptions{xmltag} =
              \%Foswiki::Plugins::WysiwygPlugin::xmltag;
            Foswiki::Plugins::WysiwygPlugin::Handlers::addXMLTag( 'customtag',
                sub { 0 } );
        },
        html => '<p>'
          . $PROTECTON
          . '&lt;customtag&gt;'
          . $PROTECTOFF
          . 'some &gt;'
          . TranslatorTests::encodedWhitespace('s2') . 'text'
          . $PROTECTON
          . '&lt;/customtag&gt;'
          . $PROTECTOFF . '</p>',
        tml      => '<customtag>some >  text</customtag>',
        finaltml => '<customtag>some &gt;  text</customtag>',
    },
    {
        exec  => TML2HTML | ROUNDTRIP,
        name  => 'CustomXmlTag',
        setup => sub {
            $extraTML2HTMLOptions{xmltag} =
              \%Foswiki::Plugins::WysiwygPlugin::xmltag;
            Foswiki::Plugins::WysiwygPlugin::Handlers::addXMLTag( 'customtag',
                sub { 1 } );
        },
        html => '<p>'
          . $PROTECTON
          . '&lt;customtag&gt;some&nbsp;&gt;&nbsp;&nbsp;text&lt;/customtag&gt;'
          . $PROTECTOFF . '</p>',
        tml => '<customtag>some >  text</customtag>',
    },
    {
        exec  => TML2HTML | ROUNDTRIP,
        name  => 'CustomXmlTagCallbackChangesText',
        setup => sub {
            $extraTML2HTMLOptions{xmltag} =
              \%Foswiki::Plugins::WysiwygPlugin::xmltag;
            Foswiki::Plugins::WysiwygPlugin::Handlers::addXMLTag( 'customtag',
                sub { $_[0] =~ s/some/different/; return 1; } );
        },
        html => '<p>'
          . $PROTECTON
          . '&lt;customtag&gt;different&nbsp;&gt;&nbsp;&nbsp;text&lt;/customtag&gt;'
          . $PROTECTOFF . '</p>',
        tml      => '<customtag>some >  text</customtag>',
        finaltml => '<customtag>different >  text</customtag>',
    },
    {
        exec  => TML2HTML | ROUNDTRIP,
        name  => 'CustomXmlTagDefaultCallback',
        setup => sub {
            $extraTML2HTMLOptions{xmltag} =
              \%Foswiki::Plugins::WysiwygPlugin::xmltag;
            Foswiki::Plugins::WysiwygPlugin::Handlers::addXMLTag('customtag');
        },
        html => '<p>'
          . $PROTECTON
          . '&lt;customtag&gt;some&nbsp;&gt;&nbsp;&nbsp;text&lt;/customtag&gt;'
          . $PROTECTOFF . '</p>',
        tml => '<customtag>some >  text</customtag>',
    },
    {
        exec  => TML2HTML | ROUNDTRIP,
        name  => 'CustomXmlTagWithAttributes',
        setup => sub {
            $extraTML2HTMLOptions{xmltag} =
              \%Foswiki::Plugins::WysiwygPlugin::xmltag;
            Foswiki::Plugins::WysiwygPlugin::Handlers::addXMLTag( 'customtag',
                sub { 1 } );
        },
        html => '<p>'
          . $PROTECTON
          . '&lt;customtag&nbsp;with="attributes"&gt;<br />&nbsp;&nbsp;formatting&nbsp;&gt;&nbsp;&nbsp;preserved<br />&lt;/customtag&gt;'
          . $PROTECTOFF . '</p>',
        tml => <<'BLAH',
<customtag with="attributes">
  formatting >  preserved
</customtag>
BLAH
    },
    {
        exec  => TML2HTML | ROUNDTRIP,
        name  => 'NestedCustomXmlTagWithAttributes',
        setup => sub {
            $extraTML2HTMLOptions{xmltag} =
              \%Foswiki::Plugins::WysiwygPlugin::xmltag;
            Foswiki::Plugins::WysiwygPlugin::Handlers::addXMLTag( 'customtag',
                sub { 1 } );
        },
        html => '<p>'
          . $PROTECTON
          . '&lt;customtag&gt;<br />&nbsp;&nbsp;formatting&nbsp;&gt;&nbsp;&nbsp;preserved<br />'
          . '&nbsp;&nbsp;&nbsp;&nbsp;&lt;customtag&gt;<br />'
          . '&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;banana&nbsp;&lt;&nbsp;cheese&nbsp;&lt;&lt;&nbsp;Elephant;<br />'
          . '&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;this&amp;that<br />'
          . '&nbsp;&nbsp;&nbsp;&nbsp;&lt;/customtag&gt;<br />'
          . '&lt;/customtag&gt;'
          . $PROTECTOFF . '</p>',
        tml => <<'BLAH',
<customtag>
  formatting >  preserved
    <customtag>
        banana < cheese << Elephant;
        this&that
    </customtag>
</customtag>
BLAH
    },
    {
        exec  => TML2HTML | ROUNDTRIP,
        name  => 'VerbatimInsideDot',
        setup => sub {
            $extraTML2HTMLOptions{xmltag} =
              \%Foswiki::Plugins::WysiwygPlugin::xmltag;
            Foswiki::Plugins::WysiwygPlugin::Handlers::addXMLTag( 'dot',
                sub { 1 } );
        },
        tml => <<'DOT',
<dot>
digraph G {
    open [label="<verbatim>"];
    content [label="Put arbitrary content here"];
    close [label="</verbatim>"];
    open -> content -> close;
}
</dot>
DOT
        html => '<p>'
          . $PROTECTON
          . '&lt;dot&gt;<br />'
          . 'digraph&nbsp;G&nbsp{<br />'
          . '&nbsp;&nbsp;&nbsp;&nbsp;open&nbsp;[label="&lt;verbatim&gt;"];<br />'
          . '&nbsp;&nbsp;&nbsp;&nbsp;content&nbsp;[label="Put&nbsp;arbitrary&nbsp;content&nbsp;here"];<br />'
          . '&nbsp;&nbsp;&nbsp;&nbsp;close&nbsp;[label="&lt;/verbatim&gt;"];<br />'
          . '&nbsp;&nbsp;&nbsp;&nbsp;open&nbsp;-&gt;&nbsp;content&nbsp-&gt;&nbsp;close;<br />'
          . '}<br />'
          . '&lt;/dot&gt;'
          . $PROTECTOFF . '</p>',
    },
    {
        exec  => TML2HTML | ROUNDTRIP,
        name  => 'CustomtagInsideSticky',
        setup => sub {
            $extraTML2HTMLOptions{xmltag} =
              \%Foswiki::Plugins::WysiwygPlugin::xmltag;
            Foswiki::Plugins::WysiwygPlugin::Handlers::addXMLTag( 'customtag',
                sub { 1 } );
        },
        tml =>
"<sticky><customtag>this & that\n >   the other </customtag></sticky>",
        html => $deleteme . '<p>'
          . '<div class="WYSIWYG_STICKY">'
          . '&lt;customtag&gt;'
          . 'this&nbsp;&amp;&nbsp;that<br />&nbsp;&gt;&nbsp;&nbsp;&nbsp;the&nbsp;other&nbsp;'
          . '&lt;/customtag&gt;'
          . '</div>' . '</p>'
    },
    {
        exec  => TML2HTML | ROUNDTRIP,
        name  => 'StickyInsideCustomtag',
        setup => sub {
            $extraTML2HTMLOptions{xmltag} =
              \%Foswiki::Plugins::WysiwygPlugin::xmltag;
            Foswiki::Plugins::WysiwygPlugin::Handlers::addXMLTag( 'customtag',
                sub { 1 } );
        },
        tml =>
"<customtag>this <sticky>& that\n >   the</sticky> other </customtag>",
        html => '<p>'
          . $PROTECTON
          . '&lt;customtag&gt;'
          . 'this&nbsp;'
          . '&lt;sticky&gt;'
          . '&amp;&nbsp;that<br />&nbsp;&gt;&nbsp;&nbsp;&nbsp;the'
          . '&lt;/sticky&gt;'
          . '&nbsp;other&nbsp;'
          . '&lt;/customtag&gt;'
          . $PROTECTOFF . '</p>'
    },
    {
        exec  => TML2HTML | ROUNDTRIP,
        name  => 'StickyInsideUnspecifiedCustomtag',
        setup => sub {
            $extraTML2HTMLOptions{xmltag} =
              \%Foswiki::Plugins::WysiwygPlugin::xmltag;
        },
        tml =>
"<customtag>this <sticky>& that\n >   the</sticky> other </customtag>",
        html => '<p>'
          . $PROTECTON
          . '&lt;customtag&gt;'
          . $PROTECTOFF . 'this'
          . '<div class="WYSIWYG_STICKY">'
          . '&amp;&nbsp;that<br />&nbsp;&gt;&nbsp;&nbsp;&nbsp;the'
          . '</div>' . 'other'
          . $PROTECTON
          . '&lt;/customtag&gt;'
          . $PROTECTOFF . '</p>'
    },
    {
        exec  => ROUNDTRIP,
        name  => 'UnspecifiedCustomtagInsideSticky',
        setup => sub {
            $extraTML2HTMLOptions{xmltag} =
              \%Foswiki::Plugins::WysiwygPlugin::xmltag;
        },
        tml =>
          "<sticky><customtag>this & that\n >   the other </customtag></sticky>"
    },
    {
        exec  => TML2HTML | ROUNDTRIP,
        name  => 'CustomtagInsideLiteral',
        setup => sub {
            $extraTML2HTMLOptions{xmltag} =
              \%Foswiki::Plugins::WysiwygPlugin::xmltag;
            Foswiki::Plugins::WysiwygPlugin::Handlers::addXMLTag( 'customtag',
                sub { 1 } );
        },
        tml =>
'<literal><customtag>this & that >   the other </customtag></literal>',
        html => $deleteme . '<p>'
          . '<div class="WYSIWYG_LITERAL">'
          . '<customtag>this & that >   the other </customtag>'
          . '</div>' . '</p>'
    },
    {
        exec  => TML2HTML | ROUNDTRIP,
        name  => 'UnspecifiedCustomtagInsideLiteral',
        setup => sub {
            $extraTML2HTMLOptions{xmltag} =
              \%Foswiki::Plugins::WysiwygPlugin::xmltag;
        },
        tml =>
'<literal><customtag>this & that >   the other </customtag></literal>',
        html => $deleteme . '<p>'
          . '<div class="WYSIWYG_LITERAL">'
          . '<customtag>this & that >   the other </customtag>'
          . '</div>' . '</p>'
    },
    {
        exec  => TML2HTML | ROUNDTRIP,
        name  => 'insideCustomtag',
        setup => sub {
            $extraTML2HTMLOptions{xmltag} =
              \%Foswiki::Plugins::WysiwygPlugin::xmltag;
            Foswiki::Plugins::WysiwygPlugin::Handlers::addXMLTag( 'customtag',
                sub { 1 } );
        },
        tml => <<'HERE',
<customtag>
%MACRO{"<b>X</b>"}%
this <literal>& that > the</literal> other
<verbatim>V</verbatim>
<sticky>S</sticky>
<pre>P</pre>
<!--C-->
   * Set foo=bar
http://google.com/#q=foswiki
WikiWord [[some link]]
<mytag attr="value">my content</mytag>
<img src="http://mysite.org/logo.png" alt="Alternate text" />
</customtag>
HERE
        html => '<p>'
          . $PROTECTON
          . '&lt;customtag&gt;<br />'
          . '%MACRO{"&lt;b&gt;X&lt;/b&gt;"}%<br />'
          . 'this&nbsp;&lt;literal&gt;&amp;&nbsp;that&nbsp;&gt;&nbsp;the&lt;/literal&gt;&nbsp;other<br />'
          . '&lt;verbatim&gt;V&lt;/verbatim&gt;<br />'
          . '&lt;sticky&gt;S&lt;/sticky&gt;<br />'
          . '&lt;pre&gt;P&lt;/pre&gt;<br />'
          . '&lt;!--C--&gt;<br />'
          . '&nbsp;&nbsp;&nbsp;*&nbsp;Set&nbsp;foo=bar<br />'
          . 'http://google.com/#q=foswiki<br />'
          . 'WikiWord&nbsp;[[some&nbsp;link]]<br />'
          . '&lt;mytag&nbsp;attr="value"&gt;my&nbsp;content&lt;/mytag&gt;<br />'
          . '&lt;img&nbsp;src=&quot;http://mysite.org/logo.png&quot;&nbsp;alt=&quot;Alternate&nbsp;text&quot;&nbsp;/&gt;<br />'
          . '&lt;/customtag&gt;'
          . $PROTECTOFF . '</p>'
    },
    {
        exec  => TML2HTML | ROUNDTRIP,
        name  => 'LiteralInsideUnspecifiedCustomtag',
        setup => sub {
            $extraTML2HTMLOptions{xmltag} =
              \%Foswiki::Plugins::WysiwygPlugin::xmltag;
        },
        tml =>
          '<customtag>this <literal>& that > the</literal> other </customtag>',
        html => '<p>'
          . $PROTECTON
          . '&lt;customtag&gt;'
          . $PROTECTOFF . 'this'
          . '<div class="WYSIWYG_LITERAL">'
          . '& that > the'
          . '</div>' . 'other'
          . $PROTECTON
          . '&lt;/customtag&gt;'
          . $PROTECTOFF . '</p>'
    },
    {

  # There will probably always be some markup that WysiwygPlugin cannot convert,
  # but it is not always easy to say what that markup is.
  # This test case checks the protection of unconvertable text
  # by using valid markup and forcing the conversion to fail.
        exec  => TML2HTML | ROUNDTRIP,
        name  => 'UnconvertableTextIsProtected',
        setup => sub {

       # Disable "dieOnError" to test the "protect unconvertable text" behaviour
       # which can be exercised via the REST handler
            $extraTML2HTMLOptions{dieOnError} = 0;

# Override the standard expansion function to hack in an illegal character to force the conversion to fail
            $extraTML2HTMLOptions{expandVarsInURL} = sub { return "\0"; };
        },
        tml => '<img src="%PUBURLPATH%">',
        html =>
'<div class="WYSIWYG_PROTECTED">&lt;img&nbsp;src="%PUBURLPATH%"&gt;</div>'
    },
    {
        exec => HTML2TML | ROUNDTRIP,
        name => 'TableWithRowSpan_NoTablePlugin',
        setup =>
          sub { Foswiki::Func::getContext()->{'TablePluginEnabled'} = 0; },
        html => <<"HTML",
$deleteme<table cellspacing="1" cellpadding="0" border="1">
<tr><td rowspan="2">A</td><td rowspan="3">B</td><td>X</td></tr>
<tr><td rowspan="2">C</td></tr>
<tr><td>M</td></tr>
</table>
HTML
        tml => <<'TML',
<table cellspacing="1" cellpadding="0" border="1"> <tr><td rowspan="2">A</td><td rowspan="3">B</td><td>X</td></tr> <tr><td rowspan="2">C</td></tr> <tr><td>M</td></tr> </table>
TML
        finaltml => <<'TML',
<table border='1' cellpadding='0' cellspacing='1'> <tr><td rowspan='2'>A</td><td rowspan='3'>B</td><td>X</td></tr> <tr><td rowspan='2'>C</td></tr> <tr><td>M</td></tr> </table>
TML
    },

# The handling of the rowspan carat is now defualt behaviour in 1.2, so
# commented this out
#    {
#        exec => TML2HTML | ROUNDTRIP,
#        name => 'simpleTable_NoTablePlugin',
#        setup =>
#          sub { Foswiki::Func::getContext()->{'TablePluginEnabled'} = 0; },
#        html => <<'HERE',
#<p>
#Before
#</p>
#<table border="1" cellpadding="0" cellspacing="1"><tr><th>L</th><th>C</th><th>R</th></tr><tr><td> A2</td><td style="text-align: center" class="align-center"> 2</td><td style="text-align: right" class="align-right"> 2</td></tr><tr><td> A3</td><td style="text-align: center" class="align-center"> 3</td><td style="text-align: left" class="align-left"> 3</td></tr><tr><td> A4-6</td><td> four</td><td> four</td></tr><tr><td>^</td><td> five</td><td> five</td></tr></table><p class="WYSIWYG_NBNL"/><table border="1" cellpadding="0" cellspacing="1"><tr><td>^</td><td> six</td><td> six</td></tr></table>
#<p>After</p>
#HERE
#        tml => <<'HERE',
#Before
#| *L* | *C* | *R* |
#| A2 |  2  |  2 |
#| A3 |  3  | 3  |
#| A4-6 | four | four |
#|^| five | five |
#
#|^| six | six |
#After
#
#HERE
#        finaltml => <<'HERE',
#Before
#| *L* | *C* | *R* |
#| A2 |  2  |  2 |
#| A3 |  3  | 3  |
#| A4-6 | four | four |
#| ^ | five | five |
#
#| ^ | six | six |
#After
#HERE
#    },
    {
        exec => HTML2TML,
        name => 'ttClassInTable_NoTablePlugin',
        setup =>
          sub { Foswiki::Func::getContext()->{'TablePluginEnabled'} = 0; },
        html => '<table><tr><td class="WYSIWYG_TT">Code</td></tr></table>',
        tml  => '| =Code= |'
    },
    {
        exec => TML2HTML | ROUNDTRIP,
        name => 'tmlInTable_NoTablePlugin',
        setup =>
          sub { Foswiki::Func::getContext()->{'TablePluginEnabled'} = 0; },
        html => <<"BLAH",
$deleteme<table cellspacing="1" cellpadding="0" border="1">
<tr><td> <span class="WYSIWYG_TT">Code</span> </td></tr>
<tr><td> <span class="WYSIWYG_TT">code</span> at start</td></tr>
<tr><td>ends with <span class="WYSIWYG_TT">code</span> </td></tr>

<tr><td> <b><span class="WYSIWYG_TT">Code</span></b> </td></tr>
<tr><td> <b><span class="WYSIWYG_TT">code</span></b> at start</td></tr>
<tr><td>ends with <b><span class="WYSIWYG_TT">code</span></b> </td></tr>

<tr><td> <i>Emphasis</i> </td></tr>
<tr><td> <i>emphasis</i> at start</td></tr>
<tr><td>ends with <i>emphasis</i> </td></tr>

<tr><td> <b><i>Emphasis</i></b> </td></tr>
<tr><td> <b><i>emphasis</i></b> at start</td></tr>
<tr><td>ends with <b><i>emphasis</i></b> </td></tr>

<tr><td> <b>bold</b> at start</td></tr>
<tr><td>ends with <b>bold</b> </td></tr>
</table>
BLAH
        tml => <<'BLAH',
| =Code= |
| =code= at start |
| ends with =code= |
| ==Code== |
| ==code== at start |
| ends with ==code== |
| _Emphasis_ |
| _emphasis_ at start |
| ends with _emphasis_ |
| __Emphasis__ |
| __emphasis__ at start |
| ends with __emphasis__ |
| *bold* at start |
| ends with *bold* |
BLAH
    },
    {
        exec => HTML2TML,
        name => 'Item12448_IgnoreDefaultAttrs',
        html => <<'HERE',
<table border="1" cellspacing="1" cellpadding="0">
<tbody>
<tr>a0<td>a1</td><td>a2</td><td>a3</td></tr>
<tr>b0<td colspan="2">b1</td><td>b3</td></tr>
<tr>c0<td>c1</td><td>c2</td><td>c3</td></tr>
</tbody>
</table>
HERE
        tml => <<'HERE'
| a1 | a2 | a3 |
| b1 || b3 |
| c1 | c2 | c3 |
HERE
    },

    #<tr><td border-style: solid; border-width: 1px;">asdf</td>
    {
        exec => HTML2TML,
        name => 'Item12448_PreserveTableCellAttrs',
        html => <<'HERE',
<table border="1" cellspacing="1" cellpadding="0">
<tbody>
<th><td style="border-color: #35c953; ">asdf</td></th>
</tbody>
</table>
<p/><p/>
<table border="1" cellspacing="1" cellpadding="0">
<tbody>
<tr><td style="background-color: #e9154c;">asdf</td></tr>
</tbody>
</table>
HERE
        tml => <<'HERE'
<table border='1' cellpadding='0' cellspacing='1'> <tbody> <th><td style='border-color: #35c953; '>asdf</td></th> </tbody> </table>

<table border='1' cellpadding='0' cellspacing='1'> <tbody> <tr><td style='background-color: #e9154c;'>asdf</td></tr> </tbody> </table>
HERE
    },
    {
        exec => HTML2TML,
        name => 'Item12448_PreserveTableAttrs',
        html => <<'HERE',
<table border="0" cellspacing="1" cellpadding="0" style="background-color: #e9154c;">
<tbody>
<tr>a0<td>a1</td><td>a2</td><td>a3</td></tr>
<tr>b0<td colspan="2">b1</td><td>b3</td></tr>
<tr>c0<td>c1</td><td>c2</td><td>c3</td></tr>
</tbody>
</table>
<p/>
<p/>
<table border="1" cellspacing="9" cellpadding="0">
<tbody>
<tr>a0<td>a1</td><td>a2</td><td>a3</td></tr>
<tr>b0<td colspan="2">b1</td><td>b3</td></tr>
<tr>c0<td>c1</td><td>c2</td><td>c3</td></tr>
</tbody>
</table>
<p/>
<p/>
<table border="1" cellspacing="1" cellpadding="3">
<tbody>
<tr>a0<td>a1</td><td>a2</td><td>a3</td></tr>
<tr>b0<td colspan="2">b1</td><td>b3</td></tr>
<tr>c0<td>c1</td><td>c2</td><td>c3</td></tr>
</tbody>
</table>
<p/>
<p/>
<table border="1" cellspacing="1" cellpadding="0" style="background-color: #e9154c;">
<tbody>
<tr>a0<td>a1</td><td>a2</td><td>a3</td></tr>
<tr>b0<td colspan="2">b1</td><td>b3</td></tr>
<tr>c0<td>c1</td><td>c2</td><td>c3</td></tr>
</tbody>
</table>
HERE
        tml => <<'HERE'
<table border='0' cellpadding='0' cellspacing='1' style='background-color: #e9154c;'> <tbody> <tr>a0<td>a1</td><td>a2</td><td>a3</td></tr> <tr>b0<td colspan='2'>b1</td><td>b3</td></tr> <tr>c0<td>c1</td><td>c2</td><td>c3</td></tr> </tbody> </table>

<table border='1' cellpadding='0' cellspacing='9'> <tbody> <tr>a0<td>a1</td><td>a2</td><td>a3</td></tr> <tr>b0<td colspan='2'>b1</td><td>b3</td></tr> <tr>c0<td>c1</td><td>c2</td><td>c3</td></tr> </tbody> </table>

<table border='1' cellpadding='3' cellspacing='1'> <tbody> <tr>a0<td>a1</td><td>a2</td><td>a3</td></tr> <tr>b0<td colspan='2'>b1</td><td>b3</td></tr> <tr>c0<td>c1</td><td>c2</td><td>c3</td></tr> </tbody> </table>

<table border='1' cellpadding='0' cellspacing='1' style='background-color: #e9154c;'> <tbody> <tr>a0<td>a1</td><td>a2</td><td>a3</td></tr> <tr>b0<td colspan='2'>b1</td><td>b3</td></tr> <tr>c0<td>c1</td><td>c2</td><td>c3</td></tr> </tbody> </table>
HERE
    },
    {
        exec => HTML2TML,
        name => 'kupuTable_NoTablePlugin',
        setup =>
          sub { Foswiki::Func::getContext()->{'TablePluginEnabled'} = 0; },
        html => <<'HERE',
<table cellspacing="1" cellpadding="0" border="1" class="plain" _moz_resizing="true">
<tbody>
<tr>a0<td>a1</td><td>a2</td><td>a3</td></tr>
<tr>b0<td colspan="2">b1</td><td>b3</td></tr>
<tr>c0<td>c1</td><td>c2</td><td>c3</td></tr>
</tbody>
</table>
HERE
        tml => <<'HERE'
| a1 | a2 | a3 |
| b1 || b3 |
| c1 | c2 | c3 |
HERE
    },
    {
        exec => TML2HTML | ROUNDTRIP,
        name => 'tableWithColSpans_NoTablePlugin',
        setup =>
          sub { Foswiki::Func::getContext()->{'TablePluginEnabled'} = 0; },
        html => <<'HERE',
<p>abcd
</p>
<table cellspacing="1" cellpadding="0" border="1">
<tr><td colspan="2">efg</td><td>&nbsp;</td></tr>
<tr><td colspan="3"></td></tr></table>
<p>hijk
</p>
HERE
        tml => <<'HERE',
abcd
| efg || |
||||
hijk
HERE
        finaltml => <<'HERE',
abcd
| efg || |
| |||
hijk
HERE
    },
    {
        exec => ROUNDTRIP,
        name => 'Item4410_NoTablePlugin',
        setup =>
          sub { Foswiki::Func::getContext()->{'TablePluginEnabled'} = 0; },
        tml => <<'HERE',
   * x
| Y |
HERE
        html =>
'<ul><li>x</li></ul><table cellspacing="1" cellpadding="0" border="1"><tr><td>Y</td></tr></table>',
    },
    {
        exec => HTML2TML,
        name => 'tableInnaBun_NoTablePlugin',
        setup =>
          sub { Foswiki::Func::getContext()->{'TablePluginEnabled'} = 0; },
        html => <<'JUNK',
<ul>
<li> List item</li><li><table><tbody><tr><td>&nbsp;11</td><td>&nbsp;21</td></tr><tr><td>12&nbsp;</td><td>&nbsp;22</td></tr></tbody></table></li><li>crap</li>
</ul>
JUNK
        tml => <<'JUNX',
   * List item
   * <table><tbody><tr><td> 11</td><td> 21</td></tr><tr><td>12 </td><td> 22</td></tr></tbody></table>
   * crap
JUNX
    },
    {
        exec => TML2HTML | HTML2TML,
        name => 'Item4700_NoTablePlugin',
        setup =>
          sub { Foswiki::Func::getContext()->{'TablePluginEnabled'} = 0; },
        tml => <<'EXPT',
| ex | per | iment |
| exper | iment ||
| expe || riment |
|| exper | iment |
EXPT
        finaltml => <<'EXPT',
| ex | per | iment |
| exper | iment ||
| expe || riment |
| | exper | iment |
EXPT
        html => <<"HEXPT",
$deleteme<table cellspacing="1" cellpadding="0" border="1">
<tr><td>ex</td><td>per</td><td>iment</td></tr>
<tr><td>exper</td><td colspan="2">iment</td></tr>
<tr><td colspan="2">expe</td><td>riment</td></tr>
<tr><td></td><td>exper</td><td>iment</td></tr>
</table>
HEXPT
    },
    {
        exec => ROUNDTRIP,
        name => 'Item4700_2_NoTablePlugin',
        setup =>
          sub { Foswiki::Func::getContext()->{'TablePluginEnabled'} = 0; },
        tml => <<'EXPT',
| ex | per | iment |
| exper | iment ||
| expe || riment |
| | exper | iment |
EXPT
        html => <<"HEXPT",
$deleteme<table cellspacing="1" cellpadding="0" border="1">
<tr><td>ex</td><td>per</td><td>iment</td></tr>
<tr><td>exper</td><td colspan="2">iment</td></tr>
<tr><td colspan="2">expe</td><td>riment</td></tr>
<tr><td></td><td>exper</td><td>iment</td></tr>
</table>
HEXPT
    },
    {
        name => 'Item4855_NoTablePlugin',
        setup =>
          sub { Foswiki::Func::getContext()->{'TablePluginEnabled'} = 0; },
        exec => TML2HTML,
        tml  => <<'HERE',
| [[LegacyTopic1]] | Main.SomeGuy |
%TABLESEP%
%SEARCH{"legacy" nonoise="on" format="| [[$topic]] | [[$wikiname]] |"}%
HERE
        html => <<"THERE",
$deleteme<div class="foswikiTableAndMacros">
<table cellspacing="1" cellpadding="0" border="1">
<tr><td><a class="TMLlink" data-wikiword="LegacyTopic1" href="LegacyTopic1">LegacyTopic1</a></td><td><a data-wikiword="Main.SomeGuy" href="Main.SomeGuy">Main.SomeGuy</a></td></tr>
</table>
<span class="WYSIWYG_PROTECTED"><br />%TABLESEP%</span>
<span class="WYSIWYG_PROTECTED"><br />%SEARCH{"legacy"&nbsp;nonoise="on"&nbsp;format="|&nbsp;[[\$topic]]&nbsp;|&nbsp;[[\$wikiname]]&nbsp;|"}%</span>
</div>
THERE
    },
    {
        name => 'Item1798_NoTablePlugin',
        setup =>
          sub { Foswiki::Func::getContext()->{'TablePluginEnabled'} = 0; },
        exec => ROUNDTRIP | TML2HTML,
        tml  => <<'HERE',
| [[LegacyTopic1]] | Main.SomeGuy |
%SEARCH{"legacy" nonoise="on" format="| [[$topic]] | [[$wikiname]] |"}%
HERE
        html => <<"THERE",
$deleteme<div class="foswikiTableAndMacros">
<table cellspacing="1" cellpadding="0" border="1">
<tr><td><a class="TMLlink" data-wikiword="LegacyTopic1" href="LegacyTopic1">LegacyTopic1</a></td><td><a data-wikiword="Main.SomeGuy" href="Main.SomeGuy">Main.SomeGuy</a></td></tr>
</table>
<span class="WYSIWYG_PROTECTED"><br />%SEARCH{"legacy"&nbsp;nonoise="on"&nbsp;format="|&nbsp;[[\$topic]]&nbsp;|&nbsp;[[\$wikiname]]&nbsp;|"}%</span>
</div>
THERE
    },
    {
        exec => HTML2TML | ROUNDTRIP,
        name => 'colorClassInTable_NoTablePlugin',
        setup =>
          sub { Foswiki::Func::getContext()->{'TablePluginEnabled'} = 0; },
        html => <<"BLAH",
$deleteme<table>
<tr><th class="WYSIWYG_COLOR" style="color:#FF0000;">Red Heading</th></tr>
<tr><td class="WYSIWYG_COLOR" style="color:#FF0000;">Red herring</td></tr>
</table>
BLAH
        tml => <<'BLAH',
| *%RED%Red Heading%ENDCOLOR%* |
| %RED%Red herring%ENDCOLOR% |
BLAH
    },
    {
        exec => HTML2TML | ROUNDTRIP,
        name => 'colorAndTtClassInTable_NoTablePlugin',
        setup =>
          sub { Foswiki::Func::getContext()->{'TablePluginEnabled'} = 0; },
        html => <<"BLAH",
$deleteme<table>
<tr><th class="WYSIWYG_COLOR WYSIWYG_TT" style="color:#FF0000;">Redder code</th></tr>
<tr><td class="WYSIWYG_COLOR WYSIWYG_TT" style="color:#FF0000;">Red code</td></tr>
</table>
BLAH
        tml => <<'BLAH',
| *%RED% =Redder code= %ENDCOLOR%* |
| %RED% =Red code= %ENDCOLOR% |
BLAH
    },
    {
        name => 'Item4969_NoTablePlugin',
        setup =>
          sub { Foswiki::Func::getContext()->{'TablePluginEnabled'} = 0; },
        exec => HTML2TML,
        html => <<'HERE',
<table cellspacing="1" cellpadding="0" border="1">
<tr><td>table element with a <hr /> horizontal rule</td></tr>
</table>
Mad Fish
HERE
        tml => <<'HERE',
| table element with a <hr /> horizontal rule |
Mad Fish
HERE
    },
    {
        name => 'Item5076_NoTablePlugin',
        setup =>
          sub { Foswiki::Func::getContext()->{'TablePluginEnabled'} = 0; },
        exec => HTML2TML,
        html => <<'HERE',
<table border="0"><tbody><tr><td><h2>Argh</h2><ul><li>Ergh&nbsp;</li></ul></td><td>&nbsp;</td></tr><tr><td>&nbsp;</td><td>&nbsp;</td></tr></tbody></table>
HERE
        tml => <<'HERE',
<table border='0'><tbody><tr><td>
---++ Argh
   * Ergh 
</td><td> </td></tr><tr><td> </td><td> </td></tr></tbody></table>
HERE
    },
    {
        name => 'Item2618_ExtraneousCaretMarkerInTables',
        exec => HTML2TML | ROUNDTRIP,
        html => <<"HERE",
$deleteme<table border="1"> <tbody> 
  <tr> <td>Foo</td> <span id="__caret"> </span> <td>a</td> </tr>
</tbody> </table>
HERE
        tml => <<'HERE',
| Foo | a |
HERE
    },
    {
        name  => 'preserveNoExistingTags',
        setup => sub {
            Foswiki::Func::setPreferencesValue(
                'WYSIWYGPLUGIN_PROTECT_EXISTING_TAGS', ',' );
        },
        exec => HTML2TML,
        tml  => <<'HERE',
<div class="bumblebee">

| <span class="foo">apple *pie* slice</span> shelf |
</div>
HERE
        finaltml => <<'CLEANED',
| apple *pie* slice shelf |
CLEANED
        html => <<'HTML',
<p class="foswikiDeleteMe">&nbsp;</p><div class="bumblebee">
<p class='WYSIWYG_NBNL'>
</p>
<table cellspacing="1" cellpadding="0" border="1">
<tr><td> <span class="foo">apple <b>pie</b> slice</span> shelf </td></tr>
</table><span style="{encoded:'n'}" class="WYSIWYG_HIDDENWHITESPACE">&nbsp;</span></div>
HTML
    },
    {
        name  => 'preserveDefaultExistingTags',
        setup => sub {
            Foswiki::Func::setPreferencesValue(
                'WYSIWYGPLUGIN_PROTECT_EXISTING_TAGS', 'NONE' );
        },
        exec => ROUNDTRIP,
        tml  => <<'HERE',
<div class='bumblebee'>

| <span class='foo'>apple *pie* slice</span> shelf |
</div>
HERE
    },
];

sub compareTML_HTML {
    my ( $this, $args ) = @_;
    $this->_testSpecificSetup($args);
    $this->SUPER::compareTML_HTML($args);
    $this->_testSpecificCleanup($args);
}

sub compareNotWysiwygEditable {
    my ( $this, $args ) = @_;
    $this->_testSpecificSetup($args);
    $this->SUPER::compareNotWysiwygEditable($args);
    $this->_testSpecificCleanup($args);
}

sub compareRoundTrip {
    my ( $this, $args ) = @_;
    $this->_testSpecificSetup($args);
    $this->SUPER::compareRoundTrip($args);
    $this->_testSpecificCleanup($args);
}

sub compareHTML_TML {
    my ( $this, $args ) = @_;
    $this->_testSpecificSetup($args);
    $this->SUPER::compareHTML_TML($args);
    $this->_testSpecificCleanup($args);
}

sub _testSpecificSetup {
    my ( $this, $args ) = @_;

    # Reset the extendable parts of WysiwygPlugin
    %Foswiki::Plugins::WysiwygPlugin::xmltag       = ();
    %Foswiki::Plugins::WysiwygPlugin::xmltagPlugin = ();

    %extraTML2HTMLOptions = ();

    # Test-specific setup
    if ( exists $args->{setup} ) {
        $args->{setup}->($this);
    }

    return;
}

sub _testSpecificCleanup {
    my ( $this, $args ) = @_;
    if ( exists $args->{cleanup} ) {
        $args->{cleanup}->($this);
    }

    return;
}

sub TML_HTMLconverterOptions {
    my $this    = shift;
    my %options = $this->SUPER::TML_HTMLconverterOptions(@_);
    for my $extraOptionName ( keys %extraTML2HTMLOptions ) {
        $options{$extraOptionName} = $extraTML2HTMLOptions{$extraOptionName};
    }
    return %options;
}

ExtendedTranslatorTests->gen_compare_tests($data);

1;
__END__
Foswiki - The Free and Open Source Wiki, http://foswiki.org/

Copyright (C) 2008-2010 Foswiki Contributors. Foswiki Contributors
are listed in the AUTHORS file in the root of this distribution.
NOTE: Please extend that file, not this notice.

Additional copyrights apply to some or all of the code in this
file as follows:

Copyright (C) 2005 ILOG http://www.ilog.fr

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version. For
more details read LICENSE in the root of this distribution.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

As per the GPL, removal of this notice is prohibited.
