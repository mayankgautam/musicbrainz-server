package MusicBrainz::Server::Data::Medium;

use Moose;
use namespace::autoclean;
use MusicBrainz::Server::Data::Release;
use MusicBrainz::Server::Entity::Medium;
use MusicBrainz::Server::Entity::Tracklist;
use MusicBrainz::Server::Entity::Track;
use MusicBrainz::Server::Data::Utils qw(
    load_subobjects
    object_to_ids
    object_to_revision_ids
    placeholders
    query_to_list
    query_to_list_limited
);

extends 'MusicBrainz::Server::Data::Entity';
with 'MusicBrainz::Server::Data::Role::NES' => { root => '/' };
with 'MusicBrainz::Server::Data::Role::Editable' => { table => 'medium' };

use Scalar::Util qw( weaken );

sub _entity_class
{
    return 'MusicBrainz::Server::Entity::Medium';
}

sub load
{
    my ($self, @objs) = @_;
    return load_subobjects($self, 'medium', @objs);
}

sub load_for_releases
{
    my ($self, @releases) = @_;

    my %id_map = object_to_revision_ids(@releases);
    my @ids = keys %id_map;

    my %response = %{
        $self->request('/release/view-mediums', \@ids)
    };

    for my $revision_id (@ids) {
        for my $release (@{ $id_map{$revision_id} }) {
            $release->mediums([
                map {
                    MusicBrainz::Server::Entity::Medium->new(
                        name => $_->{name},
                        format_id => $_->{format},
                        position => $_->{position},
                        tracklist => MusicBrainz::Server::Entity::Tracklist->new(
                            tracks => [
                                map {
                                    MusicBrainz::Server::Entity::Track->new(
                                        name => $_->{name},
                                        number => $_->{number},
                                        length => $_->{length},
                                        artist_credit_id => $_->{'artist-credit'},
                                        recording_gid => $_->{recording}
                                    )
                                } @{ $_->{tracks} }
                            ]
                        )
                    )
                } @{ $response{$revision_id} }
            ]);
        }
    }
}

sub find_by_tracklist
{
    my ($self, $tracklist_id, $limit, $offset) = @_;
    my $query = "
        SELECT
            medium.id AS m_id, medium.format AS m_format,
                medium.position AS m_position, medium.name AS m_name,
                medium.tracklist AS m_tracklist,
            release.id AS r_id, release.gid AS r_gid, release_name.name AS r_name,
                release.artist_credit AS r_artist_credit_id,
                release.date_year AS r_date_year,
                release.date_month AS r_date_month,
                release.date_day AS r_date_day,
                release.country AS r_country, release.status AS r_status,
                release.packaging AS r_packaging,
                release.release_group AS r_release_group
        FROM
            medium
            JOIN release ON release.id = medium.release
            JOIN release_name ON release.name = release_name.id
        WHERE medium.tracklist = ?
        ORDER BY date_year, date_month, date_day, musicbrainz_collate(release_name.name)
        OFFSET ?";
    return query_to_list_limited(
        $self->c->sql, $offset, $limit, sub {
            my $row = shift;
            my $medium = $self->_new_from_row($row, 'm_');
            my $release = MusicBrainz::Server::Data::Release->_new_from_row($row, 'r_');
            $medium->release($release);
            return $medium;
        },
        $query, $tracklist_id, $offset || 0);
}

sub update
{
    my ($self, $medium_id, $medium_hash) = @_;
    my $row = $self->_create_row($medium_hash);
    return unless %$row;
    $self->sql->update_row('medium', $row, { id => $medium_id });
}

sub insert
{
    my ($self, @medium_hashes) = @_;
    my $class = $self->_entity_class;
    my @created;
    for my $medium_hash (@medium_hashes) {
        my $row = $self->_create_row($medium_hash);

        push @created, $class->new(
            id => $self->sql->insert_row('medium', $row, 'id'),
            %{ $medium_hash }
        );
    }
    return @medium_hashes > 1 ? @created : $created[0];
}

sub delete
{
    my ($self, @ids) = @_;
    my @tocs = @{
        $self->sql->select_single_column_array(
            'SELECT id FROM medium_cdtoc WHERE medium IN (' . placeholders(@ids) . ')',
            @ids
        )
    };

    $self->c->model('MediumCDTOC')->delete($_) for @tocs;
    $self->sql->do('DELETE FROM medium WHERE id IN (' . placeholders(@ids) . ')', @ids);
    $self->c->model('Tracklist')->garbage_collect;
}

sub _create_row
{
    my ($self, $medium_hash) = @_;
    my %row;
    my $mapping = $self->_column_mapping;
    for my $col (qw( name format_id position tracklist_id release_id ))
    {
        next unless exists $medium_hash->{$col};
        my $mapped = $mapping->{$col} || $col;
        $row{$mapped} = $medium_hash->{$col};
    }
    return \%row;
}

sub find_for_cdstub {
    my ($self, $cdstub_toc, $limit, $offset) = @_;
    my $query =
        'SELECT ' . join(', ', $self->c->model('Release')->_columns,
                         map { "medium.$_ AS m_$_" } qw(
                             id name tracklist release position format edits_pending
                         )) . "
           FROM (
                    SELECT id, ts_rank_cd(to_tsvector('mb_simple', name), query, 2) AS rank,
                           name
                    FROM release_name, plainto_tsquery('mb_simple', ?) AS query
                    WHERE to_tsvector('mb_simple', name) @@ query
                    ORDER BY rank DESC
                    LIMIT ?
                ) AS name
           JOIN release ON name.id = release.name
           JOIN medium ON medium.release = release.id
      LEFT JOIN medium_format ON medium.format = medium_format.id
           JOIN tracklist ON medium.tracklist = tracklist.id
          WHERE track_count = ? AND (medium_format.id IS NULL OR medium_format.has_discids)
       ORDER BY name.rank DESC, musicbrainz_collate(name.name),
                release.artist_credit";

    return query_to_list(
        $self->sql, sub {
            my $row = shift;
            my $release = $self->c->model('Release')->_new_from_row($row);
            my $medium = $self->_new_from_row($row, 'm_');
            $medium->release($release);
            return $medium;
        },
        $query, $cdstub_toc->cdstub->title, 10, $cdstub_toc->track_count
    );
}

=method reorder

    reorder

Takes a map of medium ids to their new position, and reorders them. For example:

   reorder( 91 => 1, 92 => 2 )

Will move medium #91 to be in position 1 and medium #92 to be in position 2

=cut

sub reorder {
    my ($self, %ordering) = @_;
    my @medium_ids = keys %ordering;

    $self->sql->do(
        'UPDATE medium SET position = -position
          WHERE id IN (' . placeholders(@medium_ids) . ')',
        @medium_ids);

    $self->sql->do(
        'UPDATE medium SET position =
                (SELECT position
                   FROM (VALUES ' . join(', ', ('(?::INTEGER, ?::INTEGER)') x @medium_ids) . ')
                     AS mpos (medium, position)
                  WHERE mpos.medium = medium.id)
          WHERE id IN (' . placeholders(@medium_ids) . ')',
        %ordering, @medium_ids
    )
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;

=head1 COPYRIGHT

Copyright (C) 2009 Lukas Lalinsky

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
