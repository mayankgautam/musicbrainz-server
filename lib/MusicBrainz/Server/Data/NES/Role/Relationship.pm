package MusicBrainz::Server::Data::NES::Role::Relationship;
use Moose::Role;

requires 'scoped_request';

my %rel_type_to_model = (
    artist => 'NES::Artist',
    label => 'NES::Label',
    recording => 'NES::Recording',
    release => 'NES::Release',
    releaseGroup => 'NES::ReleaseGroup',
    url => 'NES::URL',
    work => 'NES::Work'
);

sub get_relationships {
    my ($self, $revision) = @_;
    my @rels =
        map {
            my $rel = $_;
            my $target_type = $rel->{'target-type'};
            my $target = $self->c->model(
                $rel_type_to_model{$target_type} // die "Unknown relationship type: $target_type"
            )->get_by_gid($rel->{target});

            MusicBrainz::Server::Entity::NES::Relationship->new(
                target => $target,
                target_gid => $rel->{target},
                link => MusicBrainz::Server::Entity::Link->new(
                    type_id => $rel->{type},
                    direction => $MusicBrainz::Server::Entity::NES::Relationship::DIRECTION_BACKWARD,
                    attributes => [
                        values %{ $self->c->model('LinkAttributeType')->get_by_ids(@{ $rel->{attributes} }) }
                    ]
                ),
                target_type => $rel->{'target-type'},
            );
        } @{
            $self->scoped_request(
                '/view-relationships',
                { revision => $revision->revision_id }
            )
        };

    for my $attribute (map { $_->link->all_attributes } @rels) {
        $attribute->root($self->c->model('LinkAttributeType')->get_by_id($attribute->root_id));
    }

    $self->c->model('LinkType')->load(map { $_->link } @rels);

    return \@rels;
}

sub load_relationships {
    my ($self, @entities) = @_;
    for my $entity (@entities) {
        $entity->relationships($self->get_relationships($entity));
    }

    use Devel::Dwarn; Dwarn \@entities;
}

1;
