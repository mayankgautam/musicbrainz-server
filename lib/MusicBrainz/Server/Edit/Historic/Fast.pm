package MusicBrainz::Server::Edit::Historic::Fast;

use strict;
use warnings;

use base 'Class::Accessor::Fast::XS';

use JSON::Any qw( XS JSON );
use Memoize;
use MusicBrainz::Server::Data::Utils qw( copy_escape );
use URI::Escape qw( uri_escape uri_unescape );

memoize('decode_value');

__PACKAGE__->mk_accessors(qw(
	migration artist_id row_id table column
	new_value previous_value yes_votes no_votes
	id editor_id 	language_id quality created_time
	expires_time close_time status data auto_edit	
	c
));

sub edit_type { }
sub historic_type { shift->edit_type }
sub related_entities { return {} }

sub to_hash { shift->data }

sub album_release_ids { shift->migration->album_release_ids(@_) }
sub find_release_group_id { shift->migration->find_release_group_id(@_) }
sub link_attribute_from_name { shift->migration->link_attribute_from_name(@_) }
sub resolve_album_id { shift->migration->resolve_album_id(@_) }
sub resolve_url_id { shift->migration->resolve_url_id(@_) }
sub resolve_release_id { shift->migration->resolve_release_id(@_) }
sub resolve_recording_id { shift->migration->resolve_recording_id(@_) }
sub artist_name { shift->migration->artist_name(@_) }
sub label_id_from_alias { shift->migration->label_id_from_alias(@_) }
sub resolve_annotation_id { shift->migration->resolve_annotation_id(@_) }

sub deserialize
{
    my ($self, $serialized) = @_;
    return {} unless $serialized;

    my %kv;
    for my $line (split /\n/, $serialized) {
        my ($k, $v) = split /=/, $line, 2;
        return undef unless defined $v;
        $kv{$k} = substr($v, 0, 5) eq "\x1BURI;"
            ? decode_value($v)
            : $v;
    }

    return \%kv;
}

sub deserialize_previous_value { shift->deserialize(shift) }
sub deserialize_new_value      { shift->deserialize(shift) }

sub decode_value
{
    my $value = shift;
    return uri_unescape(substr($value, 5));
}

sub for_copy {
    my $edit = shift;

    return join("\t",
        $edit->id,
        $edit->editor_id,
        $edit->edit_type,
        $edit->status,
        copy_escape(JSON::Any->new(utf8 => 1)->encode($edit->data)),
        $edit->yes_votes,
        $edit->no_votes,
        $edit->auto_edit,
        $edit->created_time,
        $edit->close_time,
        $edit->expires_time,
        '\N',
        1
    );
}

1;
