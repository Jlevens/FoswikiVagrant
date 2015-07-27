# See bottom of file for license and copyright information
package SpreadSheetPluginTests;
use strict;
use warnings;

use FoswikiFnTestCase();
our @ISA = qw( FoswikiFnTestCase );

use Foswiki();
use Foswiki::Plugins::SpreadSheetPlugin();
use Foswiki::Plugins::SpreadSheetPlugin::Calc();

my %skip_tests = (

    'SpreadSheetPluginTests::test_T'     => '$T not implemented',
    'SpreadSheetPluginTests::test_TODAY' => '$TODAY not implemented',
);

sub skip {
    my ( $this, $test ) = @_;

    return defined $test ? $skip_tests{$test} : undef;
}

sub set_up {
    my $this = shift;
    $this->SUPER::set_up();

    $this->{target_web} = 'TemporaryTestSpreadSheet'
      || "$this->{test_web}Target";
    $this->{target_topic} = 'SpreadSheetTestTopic'
      || "$this->{test_topic}Target";

    my $webObject = $this->populateNewWeb( $this->{target_web} );
    $webObject->finish();

#$this->{session}->{store}->createWeb( $this->{session}->{user}, $this->{target_web} );

    my $table = <<'HERE';
| *Region:* | *Sales:* |
| Northeast |  320 |
| Northwest |  580 |
| South |  240 |
| Europe |  610 |
| Asia |  220 |
| Total: |  %CALC{"$SET(inc, $SUM( $ABOVE() ))$GET(inc)"}% |
HERE

    $this->writeTopic( $this->{target_web}, $this->{target_topic}, $table );
}

sub tear_down {
    my $this = shift;

#$this->{session}->{store}->removeWeb( $this->{session}->{user}, $this->{target_web} );
    $this->removeFromStore( $this->{target_web} );

    $this->SUPER::tear_down();
}

sub writeTopic {
    my ( $this, $web, $topic, $text ) = @_;
    my ($meta) = Foswiki::Func::readTopic( $web, $topic );
    $meta->text($text);
    $meta->save();
    $meta->finish();

#$this->{session}->{store}->saveTopic( $this->{session}->{user}, $web, $topic, $text, $meta );
}

sub CALC {
    my $this = shift;
    my $str  = shift;
    my %args = (
        web   => 'Web',
        topic => 'Topic',
        @_,
    );
    my $calc = '%CALC{"' . $str . '"}%';
    return Foswiki::Plugins::SpreadSheetPlugin::Calc::CALC( $calc, $args{topic},
        $args{web} );
}

#sub test_MAIN {}

sub test_ABOVE {
    my ($this) = @_;

    # Test for TWiki Item6667
    my $inTable = <<'TABLE';
| 1 | 2 | 3 | 4 |
| 5 | 6 | 7 | 8 |
| %CALC{$SUM($ABOVE())}% | %CALC{$SUM($ABOVE())}% |
| %CALC{$ABOVE()}% | %CALC{$ABOVE()}% |
TABLE
    my $actual   = Foswiki::Func::expandCommonVariables($inTable);
    my $expected = <<'EXPECT';
| 1 | 2 | 3 | 4 |
| 5 | 6 | 7 | 8 |
| 6 | 8 |
| R1:C1..R3:C1 | R1:C2..R3:C2 |
EXPECT
    chomp $expected;
    $this->assert_equals( $expected, $actual );
}

sub test_ABS {
    my ($this) = @_;
    $this->assert( $this->CALC('$ABS(-12.5)') == 12.5 );
    $this->assert( $this->CALC('$ABS(12.5)') == 12.5 );
    $this->assert( $this->CALC('$ABS(0)') == 0 );
    $this->assert( $this->CALC('$ABS(-0)') == 0 );
    $this->assert( $this->CALC('$ABS(-0.0)') == 0 );
}

sub test_AND {
    my ($this) = @_;
    $this->assert( $this->CALC('$AND(0)') == 0 );
    $this->assert( $this->CALC('$AND(0,0)') == 0 );
    $this->assert( $this->CALC('$AND(0,0,0)') == 0 );

    $this->assert( $this->CALC('$AND(1)') == 1 );
    $this->assert( $this->CALC('$AND(1,0)') == 0 );
    $this->assert( $this->CALC('$AND(0,1)') == 0 );
    $this->assert( $this->CALC('$AND(1,0,0)') == 0 );
    $this->assert( $this->CALC('$AND(1,0,1)') == 0 );
    $this->assert( $this->CALC('$AND(0,1,0)') == 0 );
    $this->assert( $this->CALC('$AND(0,1,1)') == 0 );

    $this->assert( $this->CALC('$AND(0,0,0,0,0,1,1,1)') == 0 );
    $this->assert( $this->CALC('$AND(1,1,1,1,1,1,1,1)') == 1 );
}

sub test_AVERAGE {
    my ($this) = @_;
    $this->assert( $this->CALC('$AVERAGE(0)') == 0 );
    $this->assert( $this->CALC('$AVERAGE(1)') == 1 );
    $this->assert( $this->CALC('$AVERAGE(-1)') == -1 );
    $this->assert( $this->CALC('$AVERAGE(0,1)') == 0.5 );
    $this->assert( $this->CALC('$AVERAGE(-1,1)') == 0 );
    $this->assert( $this->CALC('$AVERAGE(-1,-1,-1,-1)') == -1 );
}

sub test_BITXOR {
    my ($this) = @_;

# TWiki compatibility (deprecated) - performs bitwise not of string for single argument
# $this->assert_equals( $this->CALC('$HEXENCODE($BITXOR(Aa))'), 'BE9E' );
# $this->assert_equals( $this->CALC('$HEXENCODE($BITXOR(1))'),  'CE' );

    $this->assert_equals( '30', $this->CALC('$HEXENCODE($BITXOR(Aa))') )
      ;    # non-numeric string,  returns 0
    $this->assert_equals( '30', $this->CALC('$HEXENCODE($BITXOR(1))') )
      ;    # Single entry, returns 0

    # Bitwise xor of integers.  12= b1100  7=b0111 = b1011 = 11
    $this->assert_equals( $this->CALC('$BITXOR(12, 7)'), '11' );

    # Bitwise xor of integers.  12= b1100  7=b0111  3 = b0011  = b1000 = 8
    $this->assert_equals( $this->CALC('$BITXOR(12, 7, 3)'), '8' );

    my $inTable = <<'TABLE';
| 7 |
| 12 |
| fred |
| 3 |
| %CALC{"$BITXOR($ABOVE())"}% |
TABLE
    my $actual   = Foswiki::Func::expandCommonVariables($inTable);
    my $expected = <<'EXPECT';
| 7 |
| 12 |
| fred |
| 3 |
| 8 |
EXPECT
    chomp $expected;
    $this->assert_equals( $expected, $actual );
}

sub test_CALCULATE {
    my ($this) = @_;
    my $macro = <<'DONE';
%CALCULATE{
  $LISTJOIN(
      $n,
      $LISTEACH(
         | $index | $item |,
         one, two, three
      )
  )
}%
DONE
    my $actual   = Foswiki::Func::expandCommonVariables($macro);
    my $expected = <<'DONE';
| 1 | one |
| 2 | two |
| 3 | three |
DONE
    $this->assert_equals( $expected, $actual );
}

sub test_CEILING {
    my ($this) = @_;
    $this->assert( $this->CALC('$CEILING(5)') == 5 );
    $this->assert( $this->CALC('$CEILING(5.0)') == 5 );
    $this->assert( $this->CALC('$CEILING(5.4)') == 6 );
    $this->assert( $this->CALC('$CEILING(05.4)') == 6 );
    $this->assert( $this->CALC('$CEILING(5.0040)') == 6 );
    $this->assert( $this->CALC('$CEILING(-5.4)') == -5 );
    $this->assert( $this->CALC('$CEILING(-05.4)') == -5 );
    $this->assert( $this->CALC('$CEILING(-05.0040)') == -5 );
}

sub test_CHAR {
    my ($this) = @_;
    $this->assert( $this->CALC('$CHAR(65)') eq 'A' );
    $this->assert( $this->CALC('$CHAR(97)') eq 'a' );
}

sub test_CODE {
    my ($this) = @_;
    $this->assert( $this->CALC('$CODE(A)') == 65 );
    $this->assert( $this->CALC('$CODE(a)') == 97 );
    $this->assert( $this->CALC('$CODE(abc)') == 97 );
}

sub test_COLUMN {
    my ($this) = @_;

    my $inTable = <<'TABLE';
| 1 | 2 | %CALC{$COLUMN()}% | 3 | 4 |
| 5 | %CALC{$COLUMN()}% | 6 | 7 | 8 |
TABLE
    my $actual   = Foswiki::Func::expandCommonVariables($inTable);
    my $expected = <<'EXPECT';
| 1 | 2 | 3 | 3 | 4 |
| 5 | 2 | 6 | 7 | 8 |
EXPECT
    chomp $expected;
    $this->assert_equals( $expected, $actual );
}

sub test_COUNTITEMS {
    my ($this) = @_;

    my $inTable = <<'TABLE';
| 1 | open |
| 5 | open |
| 7 | |
| 3 | Closed |
| tot | %CALC{"$COUNTITEMS($ABOVE())"}% |
TABLE
    my $actual   = Foswiki::Func::expandCommonVariables($inTable);
    my $expected = <<'EXPECT';
| 1 | open |
| 5 | open |
| 7 | |
| 3 | Closed |
| tot | Closed: 1<br /> open: 2 |
EXPECT
    chomp $expected;
    $this->assert_equals( $expected, $actual );
}

sub test_COUNTSTR {
    my ($this) = @_;

    my $inTable = <<'TABLE';
| 1 | open |
| 5 | open |
| 7 | |
| 3 | Closed |
| tot | %CALC{"$COUNTSTR($ABOVE())"}% |
| tot | %CALC{"$COUNTSTR($ABOVE(), Closed)"}% |
TABLE
    my $actual   = Foswiki::Func::expandCommonVariables($inTable);
    my $expected = <<'EXPECT';
| 1 | open |
| 5 | open |
| 7 | |
| 3 | Closed |
| tot | 3 |
| tot | 1 |
EXPECT
    chomp $expected;
    $this->assert_equals( $expected, $actual );
}

sub test_DEC2BIN {
    my ($this) = @_;
    $this->assert_equals( $this->CALC('$DEC2BIN(12)'),    '1100' );
    $this->assert_equals( $this->CALC('$DEC2BIN(100)'),   '1100100' );
    $this->assert_equals( $this->CALC('$DEC2BIN(100,8)'), '01100100' );

    # Width is a minimum, values not truncated.
    $this->assert_equals( $this->CALC('$DEC2BIN(100,4)'), '1100100' );

    # SMELL:  Invalid values return 0
    $this->assert_equals( $this->CALC('$DEC2BIN(A4)'), '0' );
}

sub test_BIN2DEC {
    my ($this) = @_;
    $this->assert_equals( $this->CALC('$BIN2DEC(A121)'), '3' );

    # SMELL: invalid characters removed,  remaining characters converted
    $this->assert_equals( $this->CALC('$BIN2DEC(1100100)'), '100' );

}

sub test_DEC2HEX {
    my ($this) = @_;
    $this->assert_equals( $this->CALC('$DEC2HEX(12)'),    'C' );
    $this->assert_equals( $this->CALC('$DEC2HEX(100)'),   '64' );
    $this->assert_equals( $this->CALC('$DEC2HEX(100,4)'), '0064' );

    # SMELL:  Invalid values return 0
    $this->assert_equals( $this->CALC('$DEC2HEX(A4)'), '0' );
}

sub test_HEX2DEC {
    my ($this) = @_;
    $this->assert_equals( $this->CALC('$HEX2DEC(E)'),  '14' );
    $this->assert_equals( $this->CALC('$HEX2DEC(64)'), '100' );
    $this->assert_equals( $this->CALC('$HEX2DEC(A5)'), '165' );

    # SMELL: non-hex characters are removed, then converted to decimal
    $this->assert_equals( $this->CALC('$HEX2DEC(1G5)'), '21' );
}

sub test_DEC2OCT {
    my ($this) = @_;
    $this->assert_equals( $this->CALC('$DEC2OCT(12)'),    '14' );
    $this->assert_equals( $this->CALC('$DEC2OCT(100)'),   '144' );
    $this->assert_equals( $this->CALC('$DEC2OCT(100,4)'), '0144' );

    # SMELL:  Invalid values return 0
    $this->assert_equals( $this->CALC('$DEC2OCT(A4)'), '0' );
}

sub test_OCT2DEC {
    my ($this) = @_;
    $this->assert_equals( $this->CALC('$OCT2DEC(021)'), '17' );
    $this->assert_equals( $this->CALC('$OCT2DEC(64)'),  '52' );

    # SMELL: non-hex characters are removed, then converted to decimal
    $this->assert_equals( $this->CALC('$OCT2DEC(1G5)'), '13' );
}

sub test_DEF {
    my ($this) = @_;
    $this->assert_equals( $this->CALC('$DEF(,1,2,3)'),     '1' );
    $this->assert_equals( $this->CALC('$DEF(,, ,,2,,3,)'), '2' );

    my $inTable = <<'TABLE';
|  |  |  | c | %CALC{$DEF($LEFT())}% |
|  | a |  | c | %CALC{$DEF($LEFT())}% |
|  |  |  |  | %CALC{$DEF($LEFT())}% |
|  | %CALC{$DEF($ABOVE())}%  |  |  | %CALC{$DEF($LEFT())}% |
TABLE
    my $actual   = Foswiki::Func::expandCommonVariables($inTable);
    my $expected = <<'EXPECT';
|  |  |  | c | c |
|  | a |  | c | a |
|  |  |  |  |  |
|  | a  |  |  | a |
EXPECT
    chomp $expected;
    $this->assert_equals( $expected, $actual );
}

sub test_EMPTY {
    my ($this) = @_;
    $this->assert( $this->CALC('$EMPTY(foo)') == 0 );
    $this->assert( $this->CALC('$EMPTY()') == 1 );
    $this->assert( $this->CALC('$EMPTY($TRIM( ))') == 1 );
}

sub test_EVAL {
    my ($this) = @_;
    $this->assert( $this->CALC('$EVAL(1+1)') == 2 );
    $this->assert( $this->CALC('$EVAL( (5 * 3) / 2 + 1.1 )') == 8.6 );
    $this->assert( $this->CALC('$EVAL(2+08)') == 10 );
    $this->assert( $this->CALC('$EVAL(8.0068/2)') == 4.0034 );
    $this->assert( $this->CALC('$EVAL(+68/2)') == 34 );
    $this->assert( $this->CALC('$EVAL(-68/2)') == -34 );
    $this->assert( $this->CALC('$EVAL(068/2)') == 34 );
    $this->assert( $this->CALC('$EVAL(+068/2)') == 34 );
    $this->assert( $this->CALC('$EVAL(-068/2)') == -34 );
    $this->assert( $this->CALC('$EVAL(aaaaa068/2zzzzz)') == 34 );
    $this->assert( $this->CALC('$EVAL(0068/2)') == 34 );
    $this->assert( $this->CALC('$EVAL(.0068/2)') == 0.0034 );
    $this->assert( $this->CALC('$EVAL(8.0068/2)') == 4.0034 );
    $this->assert( $this->CALC('$EVAL(8.0068/8)') == 1.00085 );
    $this->assert( $this->CALC('$EVAL(8.0068/08)') == 1.00085 );
}

sub test_EVEN {
    my ($this) = @_;
    $this->assert( $this->CALC('$EVEN(2)') == 1 );
    $this->assert( $this->CALC('$EVEN(1)') == 0 );
    $this->assert( $this->CALC('$EVEN(3)') == 0 );
    $this->assert( $this->CALC('$EVEN(0)') == 1 );
    $this->assert( $this->CALC('$EVEN(-4)') == 1 );
    $this->assert( $this->CALC('$EVEN(-1)') == 0 );
}

sub test_EXACT {
    my ($this) = @_;
    $this->assert( $this->CALC('$EXACT(foo, Foo)') == 0 );
    $this->assert( $this->CALC('$EXACT(foo, $LOWER(Foo))') == 1 );
    $this->assert( $this->CALC('$EXACT(,)') == 1 );
    $this->assert( $this->CALC('$EXACT(, )') == 1 );
    $this->assert( $this->CALC('$EXACT( , )') == 1 );
    $this->assert( $this->CALC('$EXACT( ,  )') == 1 );
    $this->assert( $this->CALC('$EXACT(  , )') == 1 );
}

sub test_EXEC {
    my ($this) = @_;

    my $topicText = <<'HERE';
%CALC{"$SET(msg,$NOEXEC(Hi $GET(name)))"}%

   * %CALC{"$SET(name, Tom)$EXEC($GET(msg))"}%
   * %CALC{"$SET(name, Jerry)$EXEC($GET(msg))"}%
HERE

    my $actual = Foswiki::Func::expandCommonVariables($topicText);

    my $expected = <<'HERE';


   * Hi Tom
   * Hi Jerry
HERE
    chomp $expected;
    $this->assert_equals( $expected, $actual );

}

sub test_EXISTS {
    my ($this) = @_;
    $this->assert(
        $this->CALC(
                '$EXISTS('
              . $this->{target_web} . '.'
              . $this->{target_topic} . ')'
        ) != 0
    );
    $this->assert( $this->CALC('$EXISTS(NonExistWeb.NonExistTopic)') == 0 );
}

sub test_EXP {
    my ($this) = @_;
    $this->assert( $this->CALC('$EXP(1)') == 2.71828182845905 );
}

sub test_FIND {
    my ($this) = @_;
    $this->assert( $this->CALC('$FIND(f, fluffy)') == 1 );
    $this->assert( $this->CALC('$FIND(f, fluffy, 2)') == 4 );
    $this->assert( $this->CALC('$FIND(@, fluffy, 1)') == 0 );
}

sub test_FILTER {
    my ($this) = @_;
    $this->assert( $this->CALC('$FILTER(f, fluffy)') eq 'luy' );
    $this->assert_equals( $this->CALC('$FILTER(an Franc, San Francisco)'),
        'Sisco' );
    $this->assert(
        $this->CALC('$FILTER($sp, The quick brown)') eq 'Thequickbrown' );
    $this->assert(
        $this->CALC('$FILTER([^a-zA-Z0-9 ], Stupid mistake*%@^! Fixed)') );
}

sub test_FLOOR {
    my ($this) = @_;
    $this->assert( $this->CALC('$FLOOR(5)') == 5 );
    $this->assert( $this->CALC('$FLOOR(5.0)') == 5 );
    $this->assert( $this->CALC('$FLOOR(5.4)') == 5 );
    $this->assert( $this->CALC('$FLOOR(05.4)') == 5 );
    $this->assert( $this->CALC('$FLOOR(05.0040)') == 5 );
    $this->assert( $this->CALC('$FLOOR(-5)') == -5 );
    $this->assert( $this->CALC('$FLOOR(-5.4)') == -6 );
    $this->assert( $this->CALC('$FLOOR(-05.4)') == -6 );
    $this->assert( $this->CALC('$FLOOR(-05.004)') == -6 );
}

sub test_FORMAT {
    my ($this) = @_;
    $this->assert(
        $this->CALC('$FORMAT(COMMA, 2, 12345.6789)') eq '12,345.68' );
    $this->assert(
        $this->CALC('$FORMAT(DOLLAR, 2, 12345.67)') eq '$12,345.67' );
    $this->assert( $this->CALC('$FORMAT(KB, 2, 1234567)')   eq '1205.63 KB' );
    $this->assert( $this->CALC('$FORMAT(MB, 2, 1234567)')   eq '1.18 MB' );
    $this->assert( $this->CALC('$FORMAT(KBMB, 2, 1234567)') eq '1.18 MB' );
    $this->assert( $this->CALC('$FORMAT(KBMB, 2, 1234567890)')   eq '1.15 GB' );
    $this->assert( $this->CALC('$FORMAT(NUMBER, 1, 12345.67)')   eq '12345.7' );
    $this->assert( $this->CALC('$FORMAT(PERCENT, 1, 0.1234567)') eq '12.3%' );
}

sub test_FORMATGMTIME {
    my ($this) = @_;

    $this->assert_equals( '01 Jan 1970 - 00 00 00',
        $this->CALC('$FORMATGMTIME(0, $day $mon $year - $hour $min $sec)') );
    $this->assert_equals( '31 Dec 1969 - 23 59 59',
        $this->CALC('$FORMATGMTIME(-1, $day $mon $year - $hour $min $sec)') );
    $this->assert_equals(
        '19 Jan 2038 - 03 14 08',
        $this->CALC(
            '$FORMATGMTIME(2147483648, $day $mon $year - $hour $min $sec)')
    );
    $this->assert_equals(
        '13 Dec 1901 - 20 45 51',
        $this->CALC(
            '$FORMATGMTIME(-2147483649, $day $mon $year - $hour $min $sec)')
    );

    $this->assert_equals(
        '2004-W53-6',
        $this->CALC(
            '$FORMATGMTIME($TIME(2005-01-01), $isoweek($year-W$wk-$day))')
    );
    $this->assert_equals(
        '2009-W01-1',
        $this->CALC(
            '$FORMATGMTIME($TIME(2008-12-29), $isoweek($year-W$wk-$day))')
    );
}

sub test_FORMATTIME {
    my ($this) = @_;

    $this->assert_equals(
        '1970/01/01 00:00:00 GMT',
        $this->CALC(
            '$FORMATTIME(0, $year/$month/$day $hour:$minute:$second GMT)')
    );
    $this->assert_equals(
        '1969/12/31 23:59:59 GMT',
        $this->CALC(
            '$FORMATTIME(-1, $year/$month/$day $hour:$minute:$second GMT)')
    );
    $this->assert_equals(
        '2038/01/19 03:14:08 GMT',
        $this->CALC(
'$FORMATTIME(2147483648, $year/$month/$day $hour:$minute:$second GMT)'
        )
    );
    $this->assert_equals(
        '1901/12/13 20:45:51 GMT',
        $this->CALC(
'$FORMATTIME(-2147483649, $year/$month/$day $hour:$minute:$second GMT)'
        )
    );

    $this->assert_equals(
        '2004-W53-6 GMT',
        $this->CALC(
            '$FORMATTIME($TIME(2005-01-01 gmt), $isoweek($year-W$wk-$day) GMT)')
    );
    $this->assert_equals(
        '2009-W01-1 GMT',
        $this->CALC(
            '$FORMATTIME($TIME(2008-12-29 gmt), $isoweek($year-W$wk-$day) GMT)')
    );

}

sub test_FORMATTIMEDIFF {
    my ($this) = @_;

    $this->assert_equals( '0 minutes',
        $this->CALC('$FORMATTIMEDIFF(min, 1, 0)') );
    $this->assert_equals( '3 hours',
        $this->CALC('$FORMATTIMEDIFF(min, 1, 200)') );
    $this->assert_equals( '3 hours and 20 minutes',
        $this->CALC('$FORMATTIMEDIFF(min, 2, 200)') );
    $this->assert_equals( '1 day',
        $this->CALC('$FORMATTIMEDIFF(min, 1, 1640)') );
    $this->assert_equals( '1 day and 3 hours',
        $this->CALC('$FORMATTIMEDIFF(min, 2, 1640)') );
    $this->assert_equals( '1 day, 3 hours and 20 minutes',
        $this->CALC('$FORMATTIMEDIFF(min, 3, 1640)') );

    $this->assert_equals( '0 minutes',
        $this->CALC('$FORMATTIMEDIFF(min, 1, -0)') );
    $this->assert_equals( '3 hours and 20 minutes',
        $this->CALC('$FORMATTIMEDIFF(min, 2, -200)') );
}

sub test_GET_SET {
    my ($this) = @_;

    my $topicText = <<"HERE";
%INCLUDE{$this->{target_web}.$this->{target_topic}}%

   * inc = %CALC{\$GET(inc)}%
%CALC{\$SET(inc, asdf)}%
   * now inc = %CALC{\$GET(inc)}%

HERE

    my $actual = Foswiki::Func::expandCommonVariables($topicText);

    my $expected = <<'HERE';
| *Region:* | *Sales:* |
| Northeast |  320 |
| Northwest |  580 |
| South |  240 |
| Europe |  610 |
| Asia |  220 |
| Total: |  1970 |

   * inc = 1970

   * now inc = asdf
HERE
    chomp $expected;
    $this->assert_equals( $actual, $expected );
}

sub test_HEXDECODE_HEXENCODE {
    my ($this) = @_;

    $this->assert_equals( $this->CALC('$HEXENCODE(123)'), '313233' );
    $this->assert_equals( $this->CALC('$HEXDECODE($HEXENCODE(123))'), '123' );
    $this->assert_equals(
        $this->CALC('$HEXENCODE($HEXDECODE(ABCDEF0123456789))'),
        'ABCDEF0123456789' );
}

sub test_IF {
    my ($this) = @_;

    #    warn '$IF not implemented';

#    $this->assert( $this->CALC( '$IF($T(R1:C5) > 1000, Over Budget, OK)' ) eq 'OK' );	#==Over Budget== if value in R1:C5 is over 1000, ==OK== if not
#    $this->assert( $this->CALC( '$IF($EXACT($T(R1:C2),), empty, $T(R1:C2))' ) eq '' );	#returns the content of R1:C2 or ==empty== if empty
#    $this->assert( $this->CALC( '$SET(val, $IF($T(R1:C2) == 0, zero, $T(R1:C2)))' ) eq '?' );	#sets a variable conditionally

    my $topicText = <<"HERE";
| 1 | | 3 | 4 | 2000 |

   * %CALC{\$IF(\$T(R1:C5) > 1000, Over Budget, OK)}%
   * %CALC{\$IF(\$EXACT(\$T(R1:C2),), empty, \$T(R1:C2))}%
%CALC{\$SET(val, \$IF(\$T(R1:C3) == 3, three, \$T(R1:C2)))}%
   * %CALC{\$GET(val)}%
HERE

    my $actual = Foswiki::Func::expandCommonVariables($topicText);

    my $expected = <<'HERE';
| 1 | | 3 | 4 | 2000 |

   * Over Budget
   * empty

   * three
HERE
    chomp $expected;
    $this->assert_equals( $expected, $actual );

}

sub test_INSERTSTRING {
    my ($this) = @_;
    $this->assert(
        $this->CALC('$INSERTSTRING(abcdefg, 2, XYZ)') eq 'abXYZcdefg' );
    $this->assert(
        $this->CALC('$INSERTSTRING(abcdefg, -2, XYZ)') eq 'abcdeXYZfg' );
}

sub test_INT {
    my ($this) = @_;
    $this->assert( $this->CALC('$INT(10 / 4)') == 2 );
    $this->assert( $this->CALC('$INT($VALUE(09))') == 9 );
    $this->assert(
        $this->CALC('$INT(10 / 0)') eq 'ERROR: Illegal division by zero' );
}

sub test_ISDIGIT {
    my ($this) = @_;
    $this->assert( $this->CALC('$ISDIGIT(123)') );
    $this->assert( !$this->CALC('$ISDIGIT(-34)') );
    $this->assert( !$this->CALC('$ISDIGIT(18.23)') );
}

sub test_ISLOWER {
    my ($this) = @_;
    $this->assert( $this->CALC('$ISLOWER(abcdefg)') );
    $this->assert( !$this->CALC('$ISLOWER(abUPcdefg)') );
    $this->assert( !$this->CALC('$ISLOWER(ab12cdefg)') );
}

sub test_ISUPPER {
    my ($this) = @_;
    $this->assert( $this->CALC('$ISUPPER(ASDFASD)') );
    $this->assert( !$this->CALC('$ISUPPER(WikiWord)') );
    $this->assert( !$this->CALC('$ISUPPER(123ABC)') );
}

sub test_ISWIKIWORD {
    my ($this) = @_;
    $this->assert( $this->CALC('$ISWIKIWORD(MyWikiWord)') );
    $this->assert( $this->CALC('$ISWIKIWORD(MyWord23)') );
    $this->assert( !$this->CALC('$ISWIKIWORD(fooBar)') );
}

sub test_LEFT {
    my ($this) = @_;

    # Test for TWiki Item6667
    my $inTable = <<'TABLE';
| 1 | 2 | <= %CALC{$SUM($LEFT())}% | 3 | 4 | %CALC{$LEFT()}% |
| 5 | 6 | <= %CALC{$SUM($LEFT())}% | 7 | 8 | %CALC{$LEFT()}% |
TABLE
    my $actual   = Foswiki::Func::expandCommonVariables($inTable);
    my $expected = <<'EXPECT';
| 1 | 2 | <= 3 | 3 | 4 | R1:C1..R1:C5 |
| 5 | 6 | <= 11 | 7 | 8 | R2:C1..R2:C5 |
EXPECT
    chomp $expected;
    $this->assert_equals( $expected, $actual );
}

sub test_LEFTSTRING {
    my ($this) = @_;
    $this->assert( $this->CALC('$LEFTSTRING(abcdefg)')      eq 'a' );
    $this->assert( $this->CALC('$LEFTSTRING(abcdefg, 0)')   eq '' );
    $this->assert( $this->CALC('$LEFTSTRING(abcdefg, 5)')   eq 'abcde' );
    $this->assert( $this->CALC('$LEFTSTRING(abcdefg, 12)')  eq 'abcdefg' );
    $this->assert( $this->CALC('$LEFTSTRING(abcdefg, -3)')  eq 'abcd' );
    $this->assert( $this->CALC('$LEFTSTRING(abcdefg, -12)') eq '' );

    my $inTable = <<'TABLE';
| 1 | 2 | 3 | 4 | 5 A | %CALC{"$LEFTSTRING($T(R$ROW():C5),1)"}% |
TABLE
    my $actual   = Foswiki::Func::expandCommonVariables($inTable);
    my $expected = <<'EXPECT';
| 1 | 2 | 3 | 4 | 5 A | 5 |
EXPECT
    chomp $expected;
    $this->assert_equals( $expected, $actual );
}

sub test_LENGTH {
    my ($this) = @_;
    $this->assert( $this->CALC('$LENGTH(abcd)') == 4 );
    $this->assert( $this->CALC('$LENGTH()') == 0 );
}

sub test_LIST {
    my ($this) = @_;

    my $inTable = <<'TABLE';
| apple | orange | kiwi | %CALC{$LIST($LEFT())}% |
| apple | orange | baseball | %CALC{$LIST($LEFT())}% |
| john | fred | %CALC{$LIST($ABOVE())}% | bananna |
| apple | orange, pink | , baseball | %CALC{$LIST($LEFT())}% |
TABLE
    my $actual   = Foswiki::Func::expandCommonVariables($inTable);
    my $expected = <<'EXPECT';
| apple | orange | kiwi | apple, orange, kiwi |
| apple | orange | baseball | apple, orange, baseball |
| john | fred | kiwi, baseball | bananna |
| apple | orange, pink | , baseball | apple, orange, pink, , baseball |
EXPECT
    chomp $expected;
    $this->assert_equals( $expected, $actual );
}

sub test_LISTIF {
    my ($this) = @_;
    $this->assert( $this->CALC('$LISTIF($item > 12, 14, 7, 25)') eq '14, 25' );
    $this->assert(
        $this->CALC('$LISTIF($NOT($EXACT($item,)), A, B, , E)') eq 'A, B, E' );
    $this->assert( $this->CALC('$LISTIF($index > 2, A, B, C, D)') eq 'C, D' );
}

sub test_LISTITEM {
    my ($this) = @_;
    $this->assert(
        $this->CALC('$LISTITEM(2, Apple, Orange, Apple, Kiwi)') eq 'Orange' );
    $this->assert(
        $this->CALC('$LISTITEM(-1, Apple, Orange, Apple, Kiwi)') eq 'Kiwi' );
}

sub test_LISTJOIN {
    my ($this) = @_;
    $this->assert( $this->CALC('$LISTJOIN(,1,2,3)')       eq '1, 2, 3' );
    $this->assert( $this->CALC('$LISTJOIN($comma,1,2,3)') eq '1,2,3' );
    $this->assert( $this->CALC('$LISTJOIN($n,1,2,3)')     eq "1\n2\n3" );
    $this->assert( $this->CALC('$LISTJOIN($sp,1,2,3)')    eq "1 2 3" );
    $this->assert( $this->CALC('$LISTJOIN( ,1,2,3)')      eq "1 2 3" );
    $this->assert( $this->CALC('$LISTJOIN(  ,1,2,3)')     eq "1  2  3" );
    $this->assert( $this->CALC('$LISTJOIN(:,1,2,3)')      eq "1:2:3" );
    $this->assert( $this->CALC('$LISTJOIN(::,1,2,3)')     eq "1::2::3" );
    $this->assert( $this->CALC('$LISTJOIN(0,1,2,3)')      eq "10203" );
    $this->assert( $this->CALC('$LISTJOIN($nop,1,2,3)')   eq '123' );
    $this->assert( $this->CALC('$LISTJOIN($empty,1,2,3)') eq '123' );
}

sub test_LISTNONEMPTY {
    my ($this) = @_;
    $this->assert_equals( $this->CALC('$LISTNONEMPTY(,1,2,3)'), '1, 2, 3' );
    $this->assert_equals( $this->CALC('$LISTNONEMPTY(,1, ,,2,,3,)'),
        '1, 2, 3' );

    my $inTable = <<'TABLE';
| a |  | c |  | e | %CALC{$LIST($LEFT())}% |
| a |  | c |  | e | %CALC{$LISTNONEMPTY($LEFT())}% |
| a |  | c | , e, | g | %CALC{$LIST($LEFT())}% |
| a |  | c | , e, | g | %CALC{$LISTNONEMPTY($LEFT())}% |
TABLE
    my $actual   = Foswiki::Func::expandCommonVariables($inTable);
    my $expected = <<'EXPECT';
| a |  | c |  | e | a, , c, , e |
| a |  | c |  | e | a, c, e |
| a |  | c | , e, | g | a, , c, , e, g |
| a |  | c | , e, | g | a, c, e, g |
EXPECT
    chomp $expected;
    $this->assert_equals( $expected, $actual );

}

sub test_LISTMAP {
    my ($this) = @_;
    $this->assert(
        $this->CALC('$LISTMAP($index: $EVAL(2 * $item), 3, 5, 7, 11)') eq
          '1: 6, 2: 10, 3: 14, 4: 22' );
}

sub test_LISTRAND {
    my ($this) = @_;
    my $list =
'Apple, Orange, Bananna, Kiwi, Moe, Curly, Larry, Shemp, Cessna, Piper, Bonanza, Cirrus, Tesla, Ford, GM, Chrysler ';
    my $rand1 = $this->CALC("\$LISTRAND($list)");
    my $rand2 = $this->CALC("\$LISTRAND($list)");
    my $rand3 = $this->CALC("\$LISTRAND($list)");
    $this->assert( $this->CALC("\$LISTSIZE($rand1)") == 1 );
    $this->assert( $this->CALC("\$LISTSIZE($rand2)") == 1 );
    $this->assert( $this->CALC("\$LISTSIZE($rand3)") == 1 );

#SMELL: This might fail,  It is random, so it's possible the same response will come back more than once.
    $this->assert( ( $rand1 ne $rand2 ) or ( $rand2 ne $rand3 ) );
    $this->assert_matches(
qr/Apple|Bananna|Orange|Kiwi|Moe|Curly|Larry|Shemp|Cessna|Piper|Bonanza|Cirrus|Tesla|Ford|GM|Chrysler/,
        $rand1
    );
    $this->assert_matches(
qr/Apple|Bananna|Orange|Kiwi|Moe|Curly|Larry|Shemp|Cessna|Piper|Bonanza|Cirrus|Tesla|Ford|GM|Chrysler/,
        $rand2
    );
    $this->assert_matches(
qr/Apple|Bananna|Orange|Kiwi|Moe|Curly|Larry|Shemp|Cessna|Piper|Bonanza|Cirrus|Tesla|Ford|GM|Chrysler/,
        $rand3
    );
}

sub test_LISTREVERSE {
    my ($this) = @_;
    $this->assert( $this->CALC('$LISTREVERSE(Apple, Orange, Apple, Kiwi)') eq
          'Kiwi, Apple, Orange, Apple' );
}

sub test_LISTSHUFFLE {
    my ($this)   = @_;
    my $list     = 'Apple, Orange, Apple, Kiwi, Moe, Curly, Larry, Shemp ';
    my $shuffle1 = $this->CALC("\$LISTSHUFFLE($list)");
    my $shuffle2 = $this->CALC("\$LISTSHUFFLE($shuffle1)");
    my $shuffle3 = $this->CALC("\$LISTSHUFFLE($list)");
    $this->assert( $this->CALC("\$LISTSIZE($shuffle1)") == 8 );
    $this->assert( $this->CALC("\$LISTSIZE($shuffle2)") == 8 );
    $this->assert( $this->CALC("\$LISTSIZE($shuffle3)") == 8 );

#SMELL: This might fail,  It is random, so it's possible the same response will come back more than once.
    $this->assert( $list     ne $shuffle1 );
    $this->assert( $list     ne $shuffle2 );
    $this->assert( $shuffle1 ne $shuffle2 );
    $this->assert( $shuffle2 ne $shuffle3 );
}

sub test_LISTSIZE {
    my ($this) = @_;
    $this->assert( $this->CALC('$LISTSIZE(Apple, Orange, Apple, Kiwi)') == 4 );
    $this->assert( $this->CALC('$LISTSIZE(Apple, , Apple, Kiwi)') == 4 );

    # Test for TWiki Item6668
    my $inTable = <<'TABLE';
| a | b | c | d | e |  %CALC{$LISTSIZE($LIST($LEFT()))}%  |
| a | b | c | d, e, f | g |  %CALC{$LISTSIZE($LIST($LEFT()))}%  |
| a |   | c | d, , f | g |  %CALC{$LISTSIZE($LIST($LEFT()))}%  |
| a |   | c | d, , f | g |  %CALC{$LISTSIZE($LISTNONEMPTY($LEFT()))}%  |
TABLE
    my $actual   = Foswiki::Func::expandCommonVariables($inTable);
    my $expected = <<'EXPECT';
| a | b | c | d | e |  5  |
| a | b | c | d, e, f | g |  7  |
| a |   | c | d, , f | g |  7  |
| a |   | c | d, , f | g |  5  |
EXPECT
    chomp $expected;
    $this->assert_equals( $expected, $actual );

}

sub test_LISTSORT {
    my ($this) = @_;
    $this->assert( $this->CALC('$LISTSORT(Apple, Orange, Apple, Kiwi)') eq
          'Apple, Apple, Kiwi, Orange' );
}

sub test_LISTTRUNCATE {
    my ($this) = @_;
    $this->assert( $this->CALC('$LISTTRUNCATE(2, Apple, Orange, Kiwi)') eq
          'Apple, Orange' );
}

sub test_LISTUNIQUE {
    my ($this) = @_;
    $this->assert( $this->CALC('$LISTUNIQUE(Apple, Orange, Apple, Kiwi)') eq
          'Apple, Orange, Kiwi' );

    # Tests for Item11079
    $this->assert_equals( 'Apple, Orange, Kiwi, Mango, Banana',
        $this->CALC('$LISTUNIQUE( Apple, Orange, Kiwi, Mango, Apple, Banana )')
    );
    $this->assert_equals( 'Orange, Apple, Kiwi, Mango, Banana',
        $this->CALC('$LISTUNIQUE( Orange, Apple, Kiwi, Mango, Banana, Apple )')
    );
    $this->assert_equals( 'Orange, Apple, Kiwi, Mango, Banana',
        $this->CALC('$LISTUNIQUE( Orange, Apple, Kiwi, Mango, Apple, Banana )')
    );
    $this->assert_equals( 'Apple, Orange, Kiwi, Mango, Banana',
        $this->CALC('$LISTUNIQUE( Apple, Orange, Kiwi, Mango, Banana, Apple )')
    );

    my $inTable = <<'TABLE';
| a | b | g |  a, , g | g | %CALC{$LISTUNIQUE($LEFT())}% |
TABLE
    my $actual   = Foswiki::Func::expandCommonVariables($inTable);
    my $expected = <<'EXPECT';
| a | b | g |  a, , g | g | a, b, g,  |
EXPECT
    chomp $expected;
    $this->assert_equals( $expected, $actual );

}

sub test_LN {
    my ($this) = @_;
    $this->assert( $this->CALC('$LN(10)') == 2.30258509299405 );

    #    $this->assert( $this->CALC( '$LN(2.30258509299405)' ) == 1 );
}

sub test_LOG {
    my ($this) = @_;
    $this->assert( $this->CALC('$LOG(1000)') == 3 );
    $this->assert( $this->CALC('$LOG(16, 2)') == 4 );
}

sub test_LOWER {
    my ($this) = @_;
    $this->assert( $this->CALC('$LOWER(lowercase)')            eq 'lowercase' );
    $this->assert( $this->CALC('$LOWER(LOWERCASE)')            eq 'lowercase' );
    $this->assert( $this->CALC('$LOWER(lOwErCaSe)')            eq 'lowercase' );
    $this->assert( $this->CALC('$LOWER()')                     eq '' );
    $this->assert( $this->CALC('$LOWER(`~!@#$%^&*_+{}|:"<>?)') eq
          q(`~!@#$%^&*_+{}|:"<>?) );
}

sub test_MAX {
    my ($this) = @_;
    $this->assert( $this->CALC('$MAX(-1,0,1,13)') == 13 );
}

sub test_MEDIAN {
    my ($this) = @_;
    $this->assert( $this->CALC('$MEDIAN(3, 9, 4, 5)') == 4.5 );
}

sub test_MIN {
    my ($this) = @_;
    $this->assert( $this->CALC('$MIN(15, 3, 28)') == 3 );
    $this->assert( $this->CALC('$MIN(-1,0,1,13)') == -1 );
}

sub test_MOD {
    my ($this) = @_;
    $this->assert( $this->CALC('$MOD(7, 3)') == 1 );
}

sub test_NOP {
    my ($this) = @_;
    $this->assert( $this->CALC('$NOP(abcd)')                   eq 'abcd' );
    $this->assert( $this->CALC('$NOP($perabc$percntdef$quot)') eq '%abc%def"' );
}

sub test_NOT {
    my ($this) = @_;
    $this->assert( $this->CALC('$NOT(0)') == 1 );
    $this->assert( $this->CALC('$NOT(1)') == 0 );
}

sub test_ODD {
    my ($this) = @_;
    $this->assert( $this->CALC('$ODD(2)') == 0 );
    $this->assert( $this->CALC('$ODD(1)') == 1 );
    $this->assert( $this->CALC('$ODD(3)') == 1 );
    $this->assert( $this->CALC('$ODD(0)') == 0 );
    $this->assert( $this->CALC('$ODD(-4)') == 0 );
    $this->assert( $this->CALC('$ODD(-1)') == 1 );
}

sub test_OR {
    my ($this) = @_;
    $this->assert( $this->CALC('$OR(0)') == 0 );
    $this->assert( $this->CALC('$OR(0,0)') == 0 );
    $this->assert( $this->CALC('$OR(0,0,0)') == 0 );

    $this->assert( $this->CALC('$OR(1)') == 1 );
    $this->assert( $this->CALC('$OR(1,0)') == 1 );
    $this->assert( $this->CALC('$OR(0,1)') == 1 );
    $this->assert( $this->CALC('$OR(1,0,0)') == 1 );
    $this->assert( $this->CALC('$OR(1,0,1)') == 1 );
    $this->assert( $this->CALC('$OR(0,1,0)') == 1 );
    $this->assert( $this->CALC('$OR(0,1,1)') == 1 );

    $this->assert( $this->CALC('$OR(0,0,0,0,0,0,0,0,0,1)') == 1 );
}

sub test_PERCENTILE {
    my ($this) = @_;
    $this->assert(
        $this->CALC('$PERCENTILE(75, 400, 200, 500, 100, 300)') == 450 );
}

sub test_PI {
    my ($this) = @_;

    # SMELL: approx. equal
    $this->assert( $this->CALC('$PI()') == 3.14159265358979 );
}

# mult
sub test_PRODUCT {
    my ($this) = @_;
    $this->assert( $this->CALC('$PRODUCT(0,1,2,3)') == 0 );
    $this->assert( $this->CALC('$PRODUCT(1,2,3)') == 6 );
    $this->assert( $this->CALC('$PRODUCT(6,4,-1)') == -24 );
    $this->assert( $this->CALC('$PRODUCT(84,-0.5)') == -42 );
    $this->assert( $this->CALC('$PRODUCT(0,4)') == 0 );

    my $inTable = <<'TABLE';
| 1 | 2 | <= %CALC{$PRODUCT($LEFT())}% | 3 | 4 |
| 5 | 6 | <= %CALC{$PRODUCT($LEFT())}% | 7 | 8 |
TABLE
    my $actual   = Foswiki::Func::expandCommonVariables($inTable);
    my $expected = <<'EXPECT';
| 1 | 2 | <= 2 | 3 | 4 |
| 5 | 6 | <= 30 | 7 | 8 |
EXPECT
    chomp $expected;
    $this->assert_equals( $expected, $actual );

    $inTable = <<'TABLE';
| 1 | 2 | %CALC{$PRODUCT($RIGHT())}% => | 3 | 4 |
| 5 | 6 | %CALC{$PRODUCT($RIGHT())}% => | 7 | 8 |
TABLE
    $actual   = Foswiki::Func::expandCommonVariables($inTable);
    $expected = <<'EXPECT';
| 1 | 2 | 12 => | 3 | 4 |
| 5 | 6 | 56 => | 7 | 8 |
EXPECT
    chomp $expected;
    $this->assert_equals( $expected, $actual );
}

sub test_PROPER {
    my ($this) = @_;
    $this->assert( $this->CALC('$PROPER(a small STEP)')   eq 'A Small Step' );
    $this->assert( $this->CALC('$PROPER(f1 (formula-1))') eq 'F1 (Formula-1)' );
}

sub test_PROPERSPACE {
    my ($this) = @_;
    $this->assert(
        $this->CALC(
            '$PROPERSPACE(Old MacDonald had a ServerFarm, EeEyeEeEyeOh)') eq
          'Old MacDonald had a Server Farm, Ee Eye Ee Eye Oh'
    );
}

sub test_RAND {
    my ($this) = @_;
    for ( 1 .. 10 ) {
        $this->assert( $this->CALC('$RAND(1)') < 1 );
        $this->assert( $this->CALC('$RAND(2)') < 2 );
        $this->assert( $this->CALC('$RAND(0.3)') < 0.3 );
    }
}

sub test_RANDSTRING {
    my ($this) = @_;
    for ( 1 .. 20 ) {
        $this->assert( length( $this->CALC('$RANDSTRING()') ) == 8 );
        $this->assert(
            $this->CALC('$RANDSTRING()') ne $this->CALC('$RANDSTRING()') );
        $this->assert_matches(
            qr/^[A-NP-Z1-9]{4},[A-NP-Z1-9]{4},[A-NP-Z1-9]{4},[A-NP-Z1-9]{4}$/,
            $this->CALC(
                "\$RANDSTRING(A..NP..Z1..9, '''xxxx,xxxx,xxxx,xxxx''')")
        );
    }
}

sub test_REPEAT {
    my ($this) = @_;
    $this->assert( $this->CALC('$REPEAT(/\, 5)') eq q{/\\/\\/\\/\\/\\} );
}

sub test_REPLACE {
    my ($this) = @_;
    $this->assert( $this->CALC('$REPLACE(abcdefghijk, 6, 5, *)') eq 'abcde*k' );
    $this->assert_equals( $this->CALC('$REPLACE(abcdefghijk, 6, 5, $comma)'),
        'abcde,k' );
    $this->assert_equals( $this->CALC('$REPLACE(abcdefghijk, 6, 5, $sp)'),
        'abcde k' );
}

sub test_RIGHT {
    my ($this) = @_;

    # Test for TWiki Item6667
    my $inTable = <<'TABLE';
| 1 | 2 |  %CALC{$SUM($RIGHT())}% => | 3 | 4 |
| 5 | 6 |  %CALC{$SUM($RIGHT())}% => | 7 | 8 |
TABLE
    my $actual   = Foswiki::Func::expandCommonVariables($inTable);
    my $expected = <<'EXPECT';
| 1 | 2 |  7 => | 3 | 4 |
| 5 | 6 |  15 => | 7 | 8 |
EXPECT
    chomp $expected;
    $this->assert_equals( $expected, $actual );
}

sub test_RIGHTSTRING {
    my ($this) = @_;
    $this->assert( $this->CALC('$RIGHTSTRING(abcdefg)')     eq 'g' );
    $this->assert( $this->CALC('$RIGHTSTRING(abcdefg, 0)')  eq '' );
    $this->assert( $this->CALC('$RIGHTSTRING(abcdefg, 5)')  eq 'cdefg' );
    $this->assert( $this->CALC('$RIGHTSTRING(abcdefg, 10)') eq 'abcdefg' );
    $this->assert( $this->CALC('$RIGHTSTRING(abcdefg, -2)') eq '' );
}

sub test_ROUND {
    my ($this) = @_;
    $this->assert( $this->CALC('$ROUND(3.15, 1)') == 3.2 );
    $this->assert( $this->CALC('$ROUND(3.149, 1)') == 3.1 );
    $this->assert( $this->CALC('$ROUND(-2.475, 2)') == -2.48 );
    $this->assert( $this->CALC('$ROUND(34.9, -1)') == 30 );
    $this->assert( $this->CALC('$ROUND(34.9)') == 35 );
    $this->assert( $this->CALC('$ROUND(34.9, 0)') == 35 );
}

sub test_ROW {
    my ($this) = @_;

    my $inTable = <<'TABLE';
| 1 | 2 | %CALC{"$ROW()"}% | 3 | 4 |
| 5 | 6 | %CALC{"$ROW()"}% | 7 | 8 |
| %CALC{"$ROW(-2)"}% | %CALC{"$ROW(2)"}% |
TABLE
    my $actual   = Foswiki::Func::expandCommonVariables($inTable);
    my $expected = <<'EXPECT';
| 1 | 2 | 1 | 3 | 4 |
| 5 | 6 | 2 | 7 | 8 |
| 1 | 5 |
EXPECT
    chomp $expected;
    $this->assert_equals( $expected, $actual );

}

sub test_combine_SET_GET {
    my ($this) = @_;

    my $inTable = <<'TABLE';
| 1 | 2 | %CALC{"$ROW()"}% | 3 | 4 |
| 5 | 6 | %CALC{"$ROW()"}% | 7 | 8 |
| %CALC{"$ROW(-2)"}% | %CALC{$ROW(2)$SET(blah,a)}% | %CALC{$SET(b,$T(R3:C2))$GET(b)}% |
| %CALC{$GET('blah')}% | %CALC{$GET(b)}% |
TABLE
    my $actual   = Foswiki::Func::expandCommonVariables($inTable);
    my $expected = <<'EXPECT';
| 1 | 2 | 1 | 3 | 4 |
| 5 | 6 | 2 | 7 | 8 |
| 1 | 5 | 5 |
| a | 5 |
EXPECT
    chomp $expected;
    $this->assert_equals( $expected, $actual );

}

sub test_SEARCH {
    my ($this) = @_;
    $this->assert( $this->CALC('$SEARCH([uy], fluffy)') == 3 );
    $this->assert( $this->CALC('$SEARCH([uy], fluffy, 4)') == 6 );
    $this->assert( $this->CALC('$SEARCH([abc], fluffy,)') == 0 );
}

sub test_SETIFEMPTY {
    my ($this) = @_;
    my $topicText = <<"HERE";
(%CALC{\$SET( result, here)}%%CALC{\$SETIFEMPTY(result, there)}%%CALC{\$SETIFEMPTY(another, there)}%)

   * %CALC{\$GET(result)}%
   * %CALC{\$GET(another)}%
HERE
    my $actual   = Foswiki::Func::expandCommonVariables($topicText);
    my $expected = <<'EXPECT';
()

   * here
   * there
EXPECT
    chomp $expected;
    $this->assert_equals( $expected, $actual );
}

sub test_SETM {
    my ($this) = @_;

    my $topicText = <<"HERE";
%INCLUDE{$this->{target_web}.$this->{target_topic}}%
%CALC{\$SETM(inc, + 100)}%
   * inc = %CALC{\$GET(inc)}%
%CALC{\$SETM(inc, / 2)}%
   * inc = %CALC{\$GET(inc)}%
HERE

    my $actual = Foswiki::Func::expandCommonVariables($topicText);

    my $expected = <<'HERE';
| *Region:* | *Sales:* |
| Northeast |  320 |
| Northwest |  580 |
| South |  240 |
| Europe |  610 |
| Asia |  220 |
| Total: |  1970 |

   * inc = 2070

   * inc = 1035
HERE
    chomp $expected;
    $this->assert_equals( $actual, $expected );
}

sub test_SIGN {
    my ($this) = @_;
    $this->assert( $this->CALC('$SIGN(-12.5)') == -1 );
    $this->assert( $this->CALC('$SIGN(12.5)') == 1 );
    $this->assert( $this->CALC('$SIGN(0)') == 0 );
    $this->assert( $this->CALC('$SIGN(-0)') == 0 );
}

sub test_SPLIT {
    my ($this) = @_;
    $this->assert_equals(
        'Apple, Orange, Kiwi',
        $this->CALC('$SPLIT(, Apple  Orange Kiwi)'),
        'Split on default space delimiter'
    );
    $this->assert_equals(
        'Apple Orange, Kiwi',
        $this->CALC('$SPLIT($comma, Apple Orange, Kiwi)'),
        'Split on comma delimiter'
    );
    $this->assert_equals(
        'Apple, Orange, Kiwi',
        $this->CALC('$SPLIT(, Apple  Orange Kiwi)'),
        'Split on default space delimiter - missing'
    );
    $this->assert_equals(
        'Apple, Orange Kiwi',
        $this->CALC('$SPLIT(-, Apple-Orange Kiwi)'),
        'Split on hyphen delimiter'
    );
    $this->assert_equals(
        'Apple, Orange, Kiwi',
        $this->CALC('$SPLIT([-:]$sp*, Apple-Orange: Kiwi)'),
        'Split on hyphen or colon followed  by 0 or more spaces'
    );
    $this->assert_equals(
        'A, p, p, l, e',
        $this->CALC('$SPLIT($empty, Apple)'),
        'Split on empty string'
    );
    $this->assert_equals(
        'A, p, p, l, e',
        $this->CALC('$SPLIT($nop, Apple)'),
        'Split on nop'
    );

    # Not documented - missing separator.
    $this->assert_equals(
        'Apple, Orange, Kiwi',
        $this->CALC('$SPLIT( Apple  Orange Kiwi)'),
        'Split on default space delimiter - missing'
    );
}

sub test_SQRT {
    my ($this) = @_;
    $this->assert( $this->CALC('$SQRT(16)') == 4 );
    $this->assert( $this->CALC('$SQRT(0)') == 0 );
    $this->assert( $this->CALC('$SQRT(1)') == 1 );

    #    $this->assert( $this->CALC( '$SQRT(-1)' ) == undef );
}

sub test_SUBSTITUTE {
    my ($this) = @_;
    $this->assert(
        $this->CALC('$SUBSTITUTE(Good morning, morning, day)') eq 'Good day' );
    $this->assert( $this->CALC('$SUBSTITUTE(Q2-2002, 2, 3)')   eq 'Q3-3003' );
    $this->assert( $this->CALC('$SUBSTITUTE(Q2-2002,2, 3, 3)') eq 'Q2-2003' );
    $this->assert_equals( $this->CALC('$SUBSTITUTE(Q2-2003-2, -, $comma)'),
        'Q2,2003,2' );
    $this->assert_equals( $this->CALC('$SUBSTITUTE(Q2 2003 2, $sp, $comma)'),
        'Q2,2003,2' );
    $this->assert(
        $this->CALC('$SUBSTITUTE(abc123def, [0-9], 9, , r)') eq 'abc999def' );
}

sub test_SUBSTRING {
    my ($this) = @_;
    $this->assert( $this->CALC('$SUBSTRING(abcdefg,hijk, 3, 5)') eq 'cdefg' );
    $this->assert(
        $this->CALC('$SUBSTRING(ab,cdefghijk, 4, 20)') eq 'cdefghijk' );
    $this->assert( $this->CALC('$SUBSTRING(a,bcdefghijk, -5, 3)') eq 'ghi' );
}

sub test_MIDSTRING {
    my ($this) = @_;
    $this->assert( $this->CALC('$MIDSTRING(abcdefghijk, 3, 5)') eq 'cdefg' );
    $this->assert(
        $this->CALC('$MIDSTRING(abcdefghijk, 3, 20)') eq 'cdefghijk' );
    $this->assert( $this->CALC('$MIDSTRING(abcdefghijk, -5, 3)') eq 'ghi' );
}

sub test_SUM {
    my ($this) = @_;
    $this->assert( $this->CALC('$SUM(0)') == 0 );
    $this->assert( $this->CALC('$SUM(1,2)') == 3 );
    $this->assert( $this->CALC('$SUM(0,0,1,1,2,3,5,8,13)') == 33 );
}

sub test_SUMDAYS {
    my ($this) = @_;
    $this->assert( $this->CALC('$SUMDAYS(2w, 1, 2d, 4h)') == 13.5 );
}

sub test_DURATION {

    # DURATION - Same as SUMDAYS - undocumented
    my ($this) = @_;
    $this->assert( $this->CALC('$SUMDAYS(2w, 1, 2d, 4h)') == 13.5 );
}

sub test_SUMPRODUCT {
    my ($this) = @_;

    my $inTable = <<'TABLE';
| 1 | 2 | 3 | 4 | 5 |
| 1 | 2 | 3 | 4 | 5 |
| 2 | 2 | 3 | 4 | 6 |
| 3 | 2 | 3 | 4 | 7 |
| %CALC{$SUMPRODUCT(R2:C1..R4:C1, R2:C5..R4:C5)}% |
TABLE
    my $actual   = Foswiki::Func::expandCommonVariables($inTable);
    my $expected = <<'EXPECT';
| 1 | 2 | 3 | 4 | 5 |
| 1 | 2 | 3 | 4 | 5 |
| 2 | 2 | 3 | 4 | 6 |
| 3 | 2 | 3 | 4 | 7 |
| 38 |
EXPECT
    chomp $expected;
    $this->assert_equals( $expected, $actual );
}

sub test_T {
    my ($this) = @_;
    warn '$T not implemented';
    $this->assert( $this->CALC('$T(R1:C5)') eq '...' );
}

sub test_TIME {
    my ($this) = @_;

    $this->assert_equals( '0',         $this->CALC('$TIME(1970/01/01 GMT)') );
    $this->assert_equals( '-31536000', $this->CALC('$TIME(1969/01/01 GMT)') );
    $this->assert_equals( '0',
        $this->CALC('$TIME(1970/01/01 - 00:00:00 GMT)') );
    $this->assert_equals( '-1',
        $this->CALC('$TIME(1969/12/31 - 23:59:59 GMT)') );
    $this->assert_equals( '2147483648',
        $this->CALC('$TIME(2038/01/19 - 03:14:08 GMT)') );
    $this->assert_equals( '-2147483649',
        $this->CALC('$TIME(1901/12/13 - 20:45:51 GMT)') );

    $this->assert_equals( '1066089600', $this->CALC('$TIME(2003/10/14 GMT)') );
    $this->assert_equals( '1066089600', $this->CALC('$TIME(DOY2003.287)') );

    $this->assert_equals(
        $this->CALC('$TIME(2003/12/31 - 23:59:59)'),
        $this->CALC('$TIME(DOY2003.365.23.59.59)')
    );

    # test year in 2 digit notation (00..79 => 20xx, 80..99 => 19xx)
    $this->assert_equals(
        '338947200',    # 28 Sep 1980
        $this->CALC('$TIME(28 Sep 80 GMT)')
    );
    $this->assert_equals(
        '938476800',    # 28 Sep 1999
        $this->CALC('$TIME(28 Sep 99 GMT)')
    );
    $this->assert_equals(
        '970099200',    # 28 Sep 2000
        $this->CALC('$TIME(28 Sep 00 GMT)')
    );
    $this->assert_equals(
        '3463084800',    # 28 Sep 2079
        $this->CALC('$TIME(28 Sep 79 GMT)')
    );
}

sub test_TIMEADD {
    my ($this) = @_;

    $this->assert(
        $this->CALC('$TIMEADD($TIME(2009/04/29 ), 90, minute)') == 1240968600 );
    $this->assert(
        $this->CALC('$TIMEADD($TIME(2009/04/29 ), 1, month)') == 1243591488 );
    $this->assert(
        $this->CALC('$TIMEADD($TIME(2009/04/29 ), 1, year)') == 1272499200 );

    Foswiki::Func::setPreferencesValue( "SPREADSHEETPLUGIN_TIMEISLOCAL", 1 );

    $this->assert( $this->CALC('$TIMEADD($TIME(2009/04/29 GMT), 90, minute)') ==
          1240968600 );
    $this->assert( $this->CALC('$TIMEADD($TIME(2009/04/29 GMT), 1, month)') ==
          1243591488 );
    $this->assert(
        $this->CALC('$TIMEADD($TIME(2009/04/29 GMT), 1, year)') == 1272499200 );

}

sub test_TIMEDIFF {
    my ($this) = @_;

    $this->assert_equals( '1.5',
        $this->CALC('$TIMEDIFF($TIME(), $EVAL($TIME()+90), minute)') );

    $this->assert_equals(
        '1',
        int(
            $this->CALC(
                '$TIMEDIFF($TIME(2008/09/28 GMT), $TIME(2010/01/28 GMT), years)'
            )
        )
    );
    $this->assert_equals(
        '16',
        int(
            $this->CALC(
                '$TIMEDIFF($TIME(2008/09/28 GMT), $TIME(2010/01/28 GMT), month)'
            )
        )
    );
    $this->assert_equals(
        '487',
        int(
            $this->CALC(
                '$TIMEDIFF($TIME(2008/09/28 GMT), $TIME(2010/01/28 GMT), days)')
        )
    );
    $this->assert_equals(
        '11688',
        int(
            $this->CALC(
                '$TIMEDIFF($TIME(2008/09/28 GMT), $TIME(2010/01/28 GMT), hours)'
            )
        )
    );
    $this->assert_equals(
        '701280',
        int(
            $this->CALC(
'$TIMEDIFF($TIME(2008/09/28 GMT), $TIME(2010/01/28 GMT), minutes)'
            )
        )
    );
    $this->assert_equals(
        '42076800',
        int(
            $this->CALC(
'$TIMEDIFF($TIME(2008/09/28 GMT), $TIME(2010/01/28 GMT), seconds)'
            )
        )
    );

    $this->assert_equals(
        '18',
        int(
            $this->CALC(
                '$TIMEDIFF($TIME(1990/1/1 GMT), $TIME(2008/1/1 GMT), year)')
        )
    );
    $this->assert_equals(
        '38',
        int(
            $this->CALC(
                '$TIMEDIFF($TIME(1970/1/1 GMT), $TIME(2008/1/1 GMT), year)')
        )
    );
    $this->assert_equals(
        '58',
        int(
            $this->CALC(
                '$TIMEDIFF($TIME(1950/1/1 GMT), $TIME(2008/1/1 GMT), year)')
        )
    );
}

sub test_TODAY {
    my ($this) = @_;
    warn '$TODAY not implemented';
}

sub test_TRANSLATE {
    my ($this) = @_;
    $this->assert( $this->CALC('$TRANSLATE(boom,bm,cl)')        eq 'cool' );
    $this->assert( $this->CALC('$TRANSLATE(one, two,$comma,;)') eq 'one; two' );
}

sub test_TRIM {
    my ($this) = @_;
    $this->assert( $this->CALC('$TRIM( eat  spaces  )') eq 'eat spaces' );
}

sub test_unknown {
    my ($this) = @_;

    $this->assert( $this->CALC('$ANOTHER(value )') eq '' );
    $this->assert( $this->CALC('$ANOTHER')         eq '$ANOTHER' );
}

sub test_UPPER {
    my ($this) = @_;
    $this->assert( $this->CALC('$UPPER(uppercase)')            eq 'UPPERCASE' );
    $this->assert( $this->CALC('$UPPER(UPPERCASE)')            eq 'UPPERCASE' );
    $this->assert( $this->CALC('$UPPER(uPpErCaSe)')            eq 'UPPERCASE' );
    $this->assert( $this->CALC('$UPPER()')                     eq '' );
    $this->assert( $this->CALC('$UPPER(`~!@#$%^&*_+{}|:"<>?)') eq
          q(`~!@#$%^&*_+{}|:"<>?) );
}

sub test_VALUE {
    my ($this) = @_;
    $this->assert( $this->CALC('$VALUE(US$1,200)') == 1200 );
    $this->assert( $this->CALC('$VALUE(PrjNotebook1234)') == 1234 );
    $this->assert( $this->CALC('$VALUE(Total: -12.5)') == -12.5 );
}

sub test_WHILE {
    my ($this) = @_;
    $this->assert_equals( '1 2 3 4 5 6 7 8 9 10 ',
        $this->CALC('$WHILE($counter<=10, $counter )') );
    $this->assert_equals(
        ' 1, 4, 9, 16, 25, 36, 49, 64, 81, 100, ',
        $this->CALC(
'$SET(i,0) $WHILE($GET(i) < 10, $SETM(i,+1)$EVAL($GET(i)*$GET(i)), )'
        )
    );
    $this->assert_equals( 'ERROR: Infinite loop (32767 cycles)',
        $this->CALC('$WHILE(1, )') );
}

sub test_WORKINGDAYS {
    my ($this) = @_;
    $this->assert(
        $this->CALC('$WORKINGDAYS($TIME(2004/07/15), $TIME(2004/08/03))') ==
          13 );

    $this->assert(
        $this->CALC('$WORKINGDAYS($TIME(2011/10/19), $TIME(2011/10/22))') ==
          3 );

    $this->assert(
        $this->CALC('$WORKINGDAYS($TIME(2011/10/22), $TIME(2011/10/23))') ==
          0 );

    $this->assert(
        $this->CALC('$WORKINGDAYS($TIME(2011/10/22), $TIME(2011/10/19))') ==
          3 );
}

sub test_XOR {
    my ($this) = @_;
    $this->assert( $this->CALC('$XOR(0, 0)') == 0 );
    $this->assert( $this->CALC('$XOR(0, 3)') == 1 );
    $this->assert( $this->CALC('$XOR(-1, 0)') == 1 );
    $this->assert( $this->CALC('$XOR(4, 0)') == 1 );
    $this->assert( $this->CALC('$XOR(1, 0, 1)') == 0 );
    $this->assert( $this->CALC('$XOR(1, 0, 0)') == 1 );
    $this->assert( $this->CALC('$XOR(1, 1, 1)') == 1 );
    $this->assert( $this->CALC('$XOR(1, joe, 1)') == 0 );
    $this->assert( $this->CALC('$XOR(10, 1)') == 0 );
}

sub test_triple_quote_escape {
    my ($this) = @_;

    $this->assert_equals( 'Good, early day',
        $this->CALC("\$SUBSTITUTE('''Good, early morning''', morning, day)") );
    $this->assert_equals( '(word)',
        $this->CALC("\$SUBSTITUTE('''(text)''', text, word)") );

    #Any strings with newlines need to be handled by the registered tag.
    my $actual = Foswiki::Func::expandCommonVariables(
        "%CALCULATE{\"\$SUBSTITUTE('''a\n(b)\nc''', b, word)\"}%");
    $this->assert_equals( "a\n(word)\nc", $actual );
}

# deprecated and undocumented
#sub test_MULT {
#}

# undocumted - same as $AVERAGE
#sub test_MEAN {
#}

1;
__END__
Foswiki - The Free and Open Source Wiki, http://foswiki.org/

Copyright (C) 2008-2014 Foswiki Contributors. Foswiki Contributors
are listed in the AUTHORS file in the root of this distribution.
NOTE: Please extend that file, not this notice.

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version. For
more details read LICENSE in the root of this distribution.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

As per the GPL, removal of this notice is prohibited.
