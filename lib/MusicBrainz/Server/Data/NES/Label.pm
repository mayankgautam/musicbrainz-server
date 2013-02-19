package MusicBrainz::Server::Data::NES::Label;
use feature 'switch';
use Moose;

use MusicBrainz::Server::Data::NES::TreeMapping ':all';
use MusicBrainz::Server::Data::Utils qw( partial_date_to_hash );
use MusicBrainz::Server::Entity::Label;
use MusicBrainz::Server::Entity::PartialDate;
use MusicBrainz::Server::Entity::Tree::Label;

with 'MusicBrainz::Server::Data::Role::NES' => {
    root => '/label'
};
with 'MusicBrainz::Server::Data::NES::CoreEntity';
with 'MusicBrainz::Server::Data::NES::Role::Alias';
with 'MusicBrainz::Server::Data::NES::Role::Annotation';
with 'MusicBrainz::Server::Data::NES::Role::Relationship';
with 'MusicBrainz::Server::Data::NES::Role::Tags' => {
    model => 'Label'
};

sub tree_class { 'MusicBrainz::Server::Entity::Tree::Label' }

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
    return MusicBrainz::Server::Entity::Label->new(
        name => $data{name},
        sort_name => $data{'sort-name'},
        comment => $data{comment},
        begin_date => MusicBrainz::Server::Entity::PartialDate->new($data{'begin-date'}),
        end_date => MusicBrainz::Server::Entity::PartialDate->new($data{'end-date'}),
        ended => $data{ended},
        type_id => $data{type},
        country_id => $data{country},
        label_code => $data{'label-code'},

        gid => $response->{mbid},
        revision_id => $response->{revision}
    );
}

sub tree_to_json {
    my ($self, $tree) = @_;

    return (
        label => do {
            my $label = $tree->label;
            {
                name => $label->name,
                'sort-name' => $label->sort_name,
                comment => $label->comment,
                'begin-date' => partial_date_to_hash($label->begin_date),
                'end-date' => partial_date_to_hash($label->end_date),
                ended => $label->ended,
                'label-code' => $label->label_code,
                type => $label->type_id,
                country => $label->country_id
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
        label => $revision,
        annotation => $self->get_annotation($revision),
        aliases => $self->get_aliases($revision),
        relationships => $self->get_relationships($revision)
    );
}

__PACKAGE__->meta->make_immutable;
1;
