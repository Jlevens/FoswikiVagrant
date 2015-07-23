# See bottom of file for license and copyright information
package Foswiki::Configure::Wizards::Test;

=begin TML

---+ package Foswiki::Configure::Wizards::Test

Wizard to test configure parameter passing

=cut

use strict;
use warnings;

use Assert;

use Foswiki::Configure::Wizard ();
our @ISA = ('Foswiki::Configure::Wizard');

=begin TML

---++ WIZARD test1

Test changing a value

=cut

sub test1 {
    my ( $this, $reporter ) = @_;

    $reporter->ERROR("No username") unless $this->param('cfgusername');
    $reporter->ERROR("No password") unless $this->param('cfgpassword');
    $reporter->ERROR("This is an error");
    $reporter->WARN("This is a warning");
    $reporter->NOTE("This is a note");
    $Foswiki::cfg{UnitTestContrib}{Configure}{STRING} = 'ROPE';
    $reporter->CHANGED('{UnitTestContrib}{Configure}{STRING}');
    return undef;
}

=begin TML

---++ WIZARD format

Test prettified value

=cut

sub format {
    my ( $this, $reporter ) = @_;
    $reporter->CHANGED('{Plugins}{ConfigurePlugin}{Test}{PERL}');
    return undef;
}

1;
__END__
Foswiki - The Free and Open Source Wiki, http://foswiki.org/

Copyright (C) 2014 Foswiki Contributors. Foswiki Contributors
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
