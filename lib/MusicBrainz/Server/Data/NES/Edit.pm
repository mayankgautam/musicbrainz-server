package MusicBrainz::Server::Data::NES::Edit;
use Moose;

use MusicBrainz::Server::Entity::Edit;

use Try::Tiny;

with 'MusicBrainz::Server::Data::Role::NES';

sub open {
    my $self = shift;
    return MusicBrainz::Server::Entity::Edit->new(
        id => $self->request('/edit/open', {})->{ref}
    );
}

sub find_for_work {
    my ($self, $work) = @_;

    my @edit_ids = @{
        $self->request('/edit/find-edits-involving-all', {
            works => [ { mbid => $work->gid } ]
        })
    };

    my @edits;
    for my $id (@edit_ids) {
        try {
            my $edit = MusicBrainz::Server::Entity::Edit->new(
                id => $id,
                html => $self->request('/edit/view-changes', {
                    edit => $id
                })->{html}
            );

            push @edits, $edit;
        };
    }

    return @edits;
}

__PACKAGE__->meta->make_immutable;
1;
