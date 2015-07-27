# Tests that specifically target the ticklish area of rev number management.
# These tests acknowledge the possibility that loading a topic may not
# return the true revision number of the topic, but some cached number
# that may or may not be correct. They also verify that if
# the topic is *force loaded* with a specific revision (which may or may
# not be in the range of known revisions) that a "true" revision
# will be loaded.
#
# These tests are conducted at the Foswiki::Meta object level, so need
# to be run for each different RCS store implementation.
#
package LoadedRevTests;
use strict;
use warnings;

use FoswikiFnTestCase();
our @ISA = ('FoswikiFnTestCase');

use Foswiki();

sub new {
    my $self = shift()->SUPER::new(@_);
    return $self;
}

sub fixture_groups {
    return ( [ 'RcsWrap', 'RcsLite' ] );
}

sub RcsWrap {
    $Foswiki::cfg{Store}{Implementation} = 'Foswiki::Store::RcsWrap';
}

sub RcsLite {
    $Foswiki::cfg{Store}{Implementation} = 'Foswiki::Store::RcsLite';
}

sub skip {
    my ( $this, $test ) = @_;

    return $this->SUPER::skip_test_if(
        $test,
        {
            condition => { with_dep => 'Foswiki,>=,1.2' },
            tests     => {
                'LoadedRevTests::verify_borked_TOPICINFO_load_behind_RcsWrap' =>
                  'Not applicable on 1.2+',
                'LoadedRevTests::verify_borked_TOPICINFO_load_behind_RcsLite' =>
                  'Not applicable on 1.2+',
            }
        }
    );
}

# Topic has not been saved. Loaded rev should be undef *even after
# a load*
sub verify_phantom_topic {
    my $this = shift;
    my $topicObject =
      $this->getUnloadedTopicObject( $this->{test_web}, "PhantomTopic" );
    $this->assert_equals( undef, $topicObject->getLoadedRev() );
    $topicObject->load();
    $this->assert_equals( undef, $topicObject->getLoadedRev() );
    $topicObject->load(1);
    $this->assert_equals( undef, $topicObject->getLoadedRev() );

    $topicObject->finish();
    ($topicObject) =
      Foswiki::Func::readTopic( $this->{test_web}, "PhantomTopic" );
    $this->assert_equals( undef, $topicObject->getLoadedRev() );
}

# Topic has been saved. Loaded rev should be defined after a load,
# and if an out-of-range rev is loaded, it should be reigned back
# to the valid range.
sub verify_good_topic {
    my $this = shift;
    my $topicObject =
      $this->getUnloadedTopicObject( $this->{test_web}, "GoodTopic" );
    $topicObject->text('Let there be light');

    # We haven't loaded a rev yet, so the loaded rev should be undef
    $this->assert_equals( undef, $topicObject->getLoadedRev() );

    # Now save. The loaded rev should be set.
    $this->assert_equals( 1, $topicObject->save() );
    $this->assert_equals( 1, $topicObject->getLoadedRev() );

    # Create a new unloaded object for what we just saved
    $topicObject->finish();
    $topicObject =
      $this->getUnloadedTopicObject( $this->{test_web}, "GoodTopic" );
    $this->assert_equals( undef, $topicObject->getLoadedRev() );

    $topicObject->load();
    $this->assert_equals( 1, $topicObject->getLoadedRev() );

    $topicObject->finish();
    ($topicObject) =
      Foswiki::Func::readTopic( $this->{test_web}, "GoodTopic", 0 );
    $this->assert_equals( 1, $topicObject->getLoadedRev() );

    $topicObject->finish();
    ($topicObject) =
      Foswiki::Func::readTopic( $this->{test_web}, "GoodTopic", 1 );
    $this->assert_equals( 1, $topicObject->getLoadedRev() );
    $topicObject->finish();
    ($topicObject) =
      Foswiki::Func::readTopic( $this->{test_web}, "GoodTopic", 2 );
    $this->assert_equals( 1, $topicObject->getLoadedRev() );
}

# Save a topic with borked TOPICINFO. The TOPICINFO should be corrected
# during the save.
sub verify_borked_TOPICINFO_save {
    my $this = shift;
    my $topicObject =
      $this->getUnloadedTopicObject( $this->{test_web}, "BorkedTOPICINFO" );
    $topicObject->text(<<SICK);
%META:TOPICINFO{version="3"}%
Houston, we may have a problem here
SICK

    # We haven't loaded a rev yet, so the loaded rev should be undef
    $this->assert_equals( undef, $topicObject->getLoadedRev() );

    $topicObject->save( forcenewrevision => 1 );

    # Now we *have* saved, and the rev should have been force-corrected
    $this->assert_equals( 1, $topicObject->getLoadedRev() );

    # Load it again to make sure
    $topicObject->finish();
    ($topicObject) =
      Foswiki::Func::readTopic( $this->{test_web}, "BorkedTOPICINFO" );
    $this->assert_equals( 1, $topicObject->getLoadedRev() );
}

sub verify_no_comma_v {
    my $this = shift;

    my $f;
    open( $f, '>', "$Foswiki::cfg{DataDir}/$this->{test_web}/NoCommaV.txt" )
      || return;
    print $f <<WHEE;
%META:TOPICINFO{version="1.3"}%
Blue. No, Green!
WHEE
    close($f);
    my ($topicObject) =
      Foswiki::Func::readTopic( $this->{test_web}, "NoCommaV" );
    $this->assert_equals( 1, $topicObject->getLoadedRev() );

    $topicObject->finish();
    $topicObject =
      $this->getUnloadedTopicObject( $this->{test_web}, "NoCommaV" );
    $topicObject->load(3);

    # We asked for an out-of-range version; even though that's the rev no
    # in the topic, it deosn't exist as a version so the loaded rev
    # should rewind to the "true" version.
    $this->assert_equals( 1, $topicObject->getLoadedRev() );

    # Reload out-of-range
    $topicObject->finish();
    $topicObject =
      $this->getUnloadedTopicObject( $this->{test_web}, "NoCommaV" );
    $topicObject->load(4);
    $this->assert_equals( 1, $topicObject->getLoadedRev() );

    # Reload undef
    $topicObject->finish();
    $topicObject =
      $this->getUnloadedTopicObject( $this->{test_web}, "NoCommaV" );
    $topicObject->load();
    $this->assert_equals( 1, $topicObject->getLoadedRev() );

    # Reload 0
    $topicObject->finish();
    $topicObject =
      $this->getUnloadedTopicObject( $this->{test_web}, "NoCommaV" );
    $topicObject->load(0);
    $this->assert_equals( 1, $topicObject->getLoadedRev() );
}

# Topic exists on disk, but the topic cache was saved by an external
# process and META:TOPICINFO is behind the latest topic in the DB.
# This case is specifically aimed at stores that decouple
# the revision history from the topic text.
# When the topic is first loaded, the version number will be imaginary.
sub verify_borked_TOPICINFO_load_behind {
    my $this = shift;

    # This test is no longer useful on 1.2.0, as the underlying bug has been
    # fixed

    # Start by creating a topic with a valid rev no (1)
    # Rev 1: Your grandmother smells of elderberries
    my ($topicObject) =
      Foswiki::Func::readTopic( $this->{test_web}, "BorkedTOPICINFO" );
    $topicObject->text(<<SICK);
Your grandmother smells of elderberries
SICK
    $topicObject->save();
    $this->assert_equals( 1, $topicObject->getLoadedRev() );

    # Rev 2: We are the knights who say Ni!
    $topicObject->text('ere, Dennis, there some lovely muck over ere');
    $topicObject->save( forcenewrevision => 1 );
    $this->assert_equals( 2, $topicObject->getLoadedRev() );

    # Stomp the cache
    my $f;

    # Wait for the clock to tick. This used to be a 1 second tick,
    # but r16350 added a 1s grace period to the file time checks,
    # so it had to be upped to 2
    my $x = time;
    while ( time == $x ) {
        sleep 2;
    }

    # .txt TOPICINFO borked: We are the knights who say Ni!
    open( $f, '>',
        "$Foswiki::cfg{DataDir}/$this->{test_web}/BorkedTOPICINFO.txt" )
      || return;
    print $f <<SICK;
%META:TOPICINFO{version="1"}%
We are the knights who say Ni!
SICK
    close($f);

    # The load shouldn't access the history
    $topicObject->finish();
    ($topicObject) =
      Foswiki::Func::readTopic( $this->{test_web}, "BorkedTOPICINFO" );
    $this->assert_equals( 1, $topicObject->getLoadedRev() )
      ;    # still reads it from the botched cache
    $this->assert_matches( qr/knights who say Ni/, $topicObject->text() );

    # Now if we load the latest, we will see a rev number of
    # 1 (because it's reading the .txt), but if we force-load any other
    # rev we should see a correct rev number
    ($topicObject) =
      Foswiki::Func::readTopic( $this->{test_web}, "BorkedTOPICINFO", 2 );
    $this->assert_equals( 2, $topicObject->getLoadedRev() );
    $this->assert_matches( qr/lovely muck/, $topicObject->text() );

    # load explicit number. This is the same rev as is is in the TOPICINFO
    # for the .txt, but that is invalid TOPICINFO so we should be loading
    # the 'true' rev 1: Your mother smells of elderberries
    $topicObject->finish();
    ($topicObject) =
      Foswiki::Func::readTopic( $this->{test_web}, "BorkedTOPICINFO", 1 );
    $this->assert_equals( 1, $topicObject->getLoadedRev() );
    $this->assert_matches( qr/elderberries/, $topicObject->text() );

    $topicObject->finish();
    ($topicObject) =
      Foswiki::Func::readTopic( $this->{test_web}, "BorkedTOPICINFO", 2 );
    $this->assert_equals( 2, $topicObject->getLoadedRev() );
    $this->assert_matches( qr/lovely muck/, $topicObject->text() );

    # load latest rev
    $topicObject->finish();
    ($topicObject) =
      Foswiki::Func::readTopic( $this->{test_web}, "BorkedTOPICINFO", 3 );
    $this->assert_equals( 3, $topicObject->getLoadedRev() )
      ;    # that's 3 because there's a checkin pending
    $this->assert_matches( qr/lovely muck/, $topicObject->text() );

    # load out of range rev
    $topicObject->finish();
    ($topicObject) =
      Foswiki::Func::readTopic( $this->{test_web}, "BorkedTOPICINFO", 4 );
    $this->assert_equals( 3, $topicObject->getLoadedRev() );
    $this->assert_matches( qr/lovely muck/, $topicObject->text() );

    #  commit the pending checkin
    $topicObject->save( forcenewrevision => 1 );
    $topicObject->finish();

    # testing rev info
    ($topicObject) =
      Foswiki::Func::readTopic( $this->{test_web}, "BorkedTOPICINFO", 0 );
    $this->assert_equals( 4, $topicObject->getLoadedRev() )
      ;  # that's the real revision now, the pending checkin got stored to rev 3

    my $info = $topicObject->getRevisionInfo();
    $this->assert_equals( $Foswiki::Users::BaseUserMapping::DEFAULT_USER_CUID,
        $info->{author} );
    $this->assert( $info->{date} );
    $this->assert_equals( 4, $info->{version} );

    # If we now save it, we should be back to corrected rev nos
    $topicObject->save( forcenewrevision => 1 );
    $topicObject->finish();
    ($topicObject) =
      Foswiki::Func::readTopic( $this->{test_web}, "BorkedTOPICINFO", 0 );
    $this->assert_equals( 5, $topicObject->getLoadedRev() );
}

1;
