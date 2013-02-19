package MusicBrainz::Server::Data::NES::CoreEntity;
use Moose::Role;

requires 'tree_to_json', 'map_core_entity';

sub create {
    my ($self, $edit, $editor, $tree) = @_;

    my $response = $self->scoped_request('/create', {
        edit => $edit->id,
        editor => $editor->id,
        $self->tree_to_json($tree)
    });

    return $self->get_revision($response->{ref})
}

sub update {
    my ($self, $edit, $editor, $base_revision, $tree) = @_;

    die 'Need a base revision' unless $base_revision;

    my $final_tree = $tree->complete
        ? $tree
        : $self->view_tree($base_revision)->merge($tree);

    my $response = $self->scoped_request('/update', {
        edit => $edit->id,
        editor => $editor->id,
        revision => $base_revision->revision_id,
        $self->tree_to_json($final_tree)
    });

    return undef;
}

sub get_revision {
    my ($self, $revision_id) = @_;
    return $self->_new_from_core_entity(
        $self->scoped_request('/view-revision', { revision => $revision_id }));
}

sub get_by_gid {
    my ($self, $gid) = @_;
    return $self->_new_from_core_entity(
        $self->scoped_request('/find-latest', { mbid => $gid }))
}

sub get_by_gids {
    my ($self, @gids) = @_;
    return {
        map {
            my $e = $self->get_by_gid($_);
            $e->gid => $e
        } @gids
    };
}

sub _new_from_core_entity {
    my ($self, $response) = @_;
    return keys %$response == 0
        ? undef
        : $self->map_core_entity($response);
}

1;
