package MusicBrainz::Server::Data::NES::Artist;
use feature 'switch';
use Moose;

use MusicBrainz::Server::Data::NES::TreeMapping ':all';
use MusicBrainz::Server::Data::Utils qw( partial_date_to_hash );
use MusicBrainz::Server::Entity::Artist;
use MusicBrainz::Server::Entity::ArtistIPI;
use MusicBrainz::Server::Entity::PartialDate;
use MusicBrainz::Server::Entity::Tree::Artist;

with 'MusicBrainz::Server::Data::Role::NES' => {
    root => '/artist'
};
with 'MusicBrainz::Server::Data::NES::CoreEntity';
with 'MusicBrainz::Server::Data::NES::Role::Alias';
with 'MusicBrainz::Server::Data::NES::Role::Annotation';
with 'MusicBrainz::Server::Data::NES::Role::IPI' => {
    entity_class => 'MusicBrainz::Server::Entity::ArtistIPI'
};
with 'MusicBrainz::Server::Data::NES::Role::Relationship';
with 'MusicBrainz::Server::Data::NES::Role::Tags' => {
    model => 'Artist'
};

sub tree_class { 'MusicBrainz::Server::Entity::Tree::Artist' }

around create => sub {
    my ($orig, $self, $edit, $editor, $tree) = @_;

    $tree->annotation('') unless $tree->annotation_set;
    $tree->aliases([]) unless $tree->aliases_set;
    $tree->relationships([]) unless $tree->relationships_set;

    $self->$orig($edit, $editor, $tree);
};

sub map_core_entity {
    my ($self, $response) = @_;
    my %data = %{ $response->{data} };
    return MusicBrainz::Server::Entity::Artist->new(
        name => $data{name},
        sort_name => $data{'sort-name'},
        comment => $data{comment},
        begin_date => MusicBrainz::Server::Entity::PartialDate->new($data{'begin-date'}),
        end_date => MusicBrainz::Server::Entity::PartialDate->new($data{'end-date'}),
        ended => $data{ended},
        gender_id => $data{gender},
        type_id => $data{type},
        country_id => $data{country},

        gid => $response->{mbid},
        revision_id => $response->{revision}
    );
}

sub tree_to_json {
    my ($self, $tree) = @_;

    return (
        artist => do {
            my $artist = $tree->artist;
            {
                name => $artist->name,
                'sort-name' => $artist->sort_name,
                comment => $artist->comment,
                'begin-date' => partial_date_to_hash($artist->begin_date),
                'end-date' => partial_date_to_hash($artist->end_date),
                ended => $artist->ended,
                gender => $artist->gender_id,
                type => $artist->type_id,
                country => $artist->country_id
            }
        },
        annotation_to_json($tree),
        aliases_to_json($tree),
        relationships_to_json($tree)
    );
}

sub view_tree {
    my ($self, $revision) = @_;

    return $self->tree_class->new(
        artist => $revision,
        annotation => $self->get_annotation($revision),
        aliases => $self->get_aliases($revision),
        relationships => $self->get_relationships($revision)
    );
}

__PACKAGE__->meta->make_immutable;
1;
