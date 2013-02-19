package MusicBrainz::Server::Data::NES::Recording;
use feature 'switch';
use Moose;

use MusicBrainz::Server::Data::NES::TreeMapping ':all';
use MusicBrainz::Server::Entity::Recording;

with 'MusicBrainz::Server::Data::Role::NES' => {
    root => '/recording'
};
with 'MusicBrainz::Server::Data::NES::CoreEntity';

around create => sub {
    my ($orig, $self, $edit, $editor, $tree) = @_;

    $tree->relationships([]) unless $tree->relationships_set;

    $self->$orig($edit, $editor, $tree);
};

sub map_core_entity {
    my ($self, $response) = @_;
    my %data = %{ $response->{data} };
    return MusicBrainz::Server::Entity::Recording->new(
        name => $data{name},
        comment => $data{comment},
        artist_credit_id => $data{'artist-credit'},
        length => $data{length},

        gid => $response->{mbid},
        revision_id => $response->{revision}
    );
}

sub tree_to_json {
    my ($self, $tree) = @_;

    return (
        'recording' => do {
            my $recording = $tree->recording;
            {
                name => $recording->name,
                comment => $recording->comment,
                artist_credit_to_json($recording->artist_credit)
            }
        },
        relationships_to_json($tree)
    );
}

sub view_tree {
    my ($self, $revision) = @_;

    return MusicBrainz::Server::Entity::Tree::Recording->new(
        recording => $revision,
        annotation => $self->get_annotation($revision),
        relationships => $self->get_relationships($revision)
    );
}

__PACKAGE__->meta->make_immutable;
1;
