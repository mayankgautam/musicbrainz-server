package MusicBrainz::Server::Entity::Tree::Label;
use Moose;

has label => (
    is => 'rw',
    predicate => 'label_set',
);

has aliases => (
    is => 'rw',
    predicate => 'aliases_set',
);

has annotation => (
    is => 'rw',
    predicate => 'annotation_set'
);

has relationships => (
    is => 'rw',
    predicate => 'relationships_set'
);

sub merge {
    my ($self, $tree) = @_;

    $self->label($tree->label)
        if ($tree->label_set);

    $self->aliases($tree->aliases)
        if ($tree->aliases_set);

    $self->annotation($tree->annotation)
        if ($tree->annotation_set);

    $self->relationships($tree->relationships)
        if ($tree->relationships_set);

    return $self;
}

sub complete {
    my $tree = shift;
    return $tree->label_set && $tree->aliases_set && $tree->annotation_set && $tree->relationships_set;
}

1;
