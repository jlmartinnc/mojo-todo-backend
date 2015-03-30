#!/usr/bin/env perl

use Mojolicious::Lite;
use File::Slurp;
use Mojo::JSON qw(decode_json encode_json);
use Data::UUID;

my $tmpfile = '/tmp/todos';

helper truncate => sub{
	write_file($tmpfile, encode_json( { 'todos' => [] } ));
};

helper getdata => sub{
        my $c = shift;
	if (!-e $tmpfile){
		$c->truncate();
	}
        return decode_json( read_file( $tmpfile ) );
};

helper setdata => sub{
        my $c = shift;
        my $data = shift;
        write_file( $tmpfile, encode_json( $data ));
};

helper todo => sub{
	my $c = shift;
	my $data = shift;
	my $id = substr(Data::UUID->new->create_str(), 0, 8);
	return {(
		'id' => $id,
		'completed' => \0,
		'title' => 'title',
		'url' => 'http://mojo-todo-backend.herokuapp.com/' . $id,
		),
		 %$data
	 };
};

app->hook(before_dispatch => sub {
		  my $c = shift;
		  $c->res->headers->header('Access-Control-Allow-Origin' => '*');
		  $c->res->headers->header('Access-Control-Allow-Headers' => 'accept, content-type');
		  $c->res->headers->header('Access-Control-Allow-Methods' => 'GET,HEAD,POST,DELETE,OPTIONS,PUT,PATCH');
	  }
  );

get '/' => sub {
	my $c = shift;
	$c->render(json => $c->getdata->{todos} );

};

get '/:id/' => sub {
	my $c = shift;
	my $data = $c->getdata();

	foreach (@{$data->{todos}}) {
		if ($_->{id} eq $c->stash('id')){
			$c->render(json => $_);
			return;
		}
	}
	$c->render(text => 'Could not find todo item');
};

options '/:id/' => sub {
	my $c = shift;
	$c->render(text => "");
};

patch '/:id/' => sub {
	my $c = shift;
	my $data = $c->getdata();

	my $todo;
	foreach (@{$data->{todos}}) {
		if ($_->{id} eq $c->stash('id')){
			$todo = $_;
			last;
		}
	}

	foreach (keys %{$c->req->json}){
		$todo->{$_} = $c->req->json->{$_};
	}
	$c->setdata($data);
	$c->render(json => $todo);
};

del '/:id/' => sub {
	my $c = shift;
	my $data = $c->getdata();

	my @todos;
	foreach (@{$data->{todos}}) {
		if ($_->{id} eq $c->stash('id')){
			next;
		}
		push @todos, $_;
	}

	$data->{todos} = \@todos;
	$c->setdata($data);
	$c->render(text => "");
};

options '/' => sub {
	my $c = shift;
	$c->render(text => "");
};

post '/' => sub {
	my $c = shift;
	my $data = $c->getdata;
	my $todo = $c->todo($c->req->json);
	push @{$data->{todos}}, $todo;
	$c->setdata($data);
	$c->render(json => $todo );
};

del '/' => sub {
	my $c = shift;
	$c->truncate();
	$c->render(json => {});
};

app->start;
