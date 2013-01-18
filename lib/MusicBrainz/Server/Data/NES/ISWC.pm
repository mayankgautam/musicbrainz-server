package MusicBrainz::Server::Data::NES::ISWC;
use Moose;
use namespace::autoclean;

with 'MusicBrainz::Server::Data::Role::NES';

sub load_for_works {
    my ($self, @works) = @_;
    my %works_by_revision_id = object_to_revision_ids(@works);
    my %iswc_map = $self->request('/iswc/find-by-work', {
        revisions => [
            map { $_->revision_id } @works
        ]
    });
    for my $key (keys %iswc_map) {
        $works_by_revision_id{$key}->iswcs([
            map {
                MusicBrainz::Server::Entity::ISWC->new(
                    iswc => $_
                )
            } @{ $iswc_map{$key} }
        ]);
    }
    return;
}

__PACKAGE__->meta->make_immutable;
1;
