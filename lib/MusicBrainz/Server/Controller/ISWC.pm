package MusicBrainz::Server::Controller::ISWC;
use Moose;

use MusicBrainz::Server::Validation qw( format_iswc is_valid_iswc );

BEGIN { extends 'MusicBrainz::Server::Controller'; }

sub base : Chained('/') PathPart('iswc') CaptureArgs(0) { }

sub load : Chained('base') PathPart('') CaptureArgs(1) {
    my ($self, $c, $iswc) = @_;

    $iswc = format_iswc($iswc);
    if (!is_valid_iswc($iswc)) {
        $self->not_found;
    }
    else {
        $c->stash(iswc => $iswc);
    }
}

sub show : Chained('load') PathPart('')
{
    my ($self, $c) = @_;

    my $iswc = $c->stash->{iswc};
    $c->model('MB')->with_nes_transaction(sub {
        my @works = @{ $c->model('NES::Work')->find_by_iswc($iswc) };
        $c->model('WorkType')->load(@works);
        # NES
        # $c->model('Work')->load_writers(@works);
        # $c->model('Work')->load_recording_artists(@works);
        $c->stash(
            works => \@works,
            template => 'iswc/index.tt',
        );
    });
}

1;

=head1 COPYRIGHT

Copyright (C) 2012 MetaBrainz Foundation

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.

=cut
